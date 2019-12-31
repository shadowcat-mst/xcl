#!/usr/bin/env xclsh

use xcl 1;
use shell;

#function usage()
#{
#    echo "$0 Usage: "
#    echo "This script runs a postgresql backup" 
#    echo "OPTIONS: "
#    echo "-h Help (prints usage)"
#    echo "-c configuration file location. Defaults to the cwd of pgbackup.sh with a file of pgbackup.config"
#    echo "-d Take a backup with a datestamp of %Y-%m-%d_%H:%M:%S_%Z, or your own date(1) compatible format string"
#}

let date = shell.which('date');
let uname = shell.which('uname');

let datestamp = date +%a;
let config = "$(shell.run pwd)/pgbackup.config";

#{{{

# ARGH

while getopts ":hd::c:" OPTIONS; do
	case ${OPTIONS} in
	h)
		usage
		exit 1
		;;
	d)
		# shellcheck disable=SC2086
		# If this is invalid, date fails and exits
		DATESTAMP="$(date $OPTARG)"
		;;
	:)
		DATESTAMP="$(date +%a_%F_%T_%Z)"
	    ;;
	c)
		CONFIG="$OPTARG"
		;;
	?)
		echo "Invalid option: ${OPTIONS}"
		usage
		exit 1
		;;
	esac
done

}}}#

shift $((OPTIND-1))

. "$CONFIG"

# Find Utilities.
let psql = shell.which('psql');
let pg_dump = shell.which('pg_dump');
let pg_dumpall = shell.which('pg_dumpall');

# Niceties.
let server_name = if [ pg_host == 'localhost' ] [ uname -n ] pg_host;

let today = date +%a;
let week_stamp = date +week_%W_of_%Y;

let os_bits = switch [uname -s]
  'Linux' {
    %.(
      :yesterday(date --date="yesterday" "+%a"),
      :last_week(date --date="last-week" "+week_%W_of_%Y")
      :md5(command.which('md5sum').curry(--tag)),
    )
  }
  'FreeBSD' {
    %.(
      :yesterday(date -v "-1d" "+%a"),
      :last_week(date -v "-1w" "+week_%W_of_%Y"),
      :md5(command.which('md5'),
    )
  }
  ? {
    say "Unsupported OS Type"
    exit 1
  }
;

if (pg_host == 'localhost') {
  pg_host = ();
} {
  pg_host = (-h, pg_host);
}

let all_ok exit_codes {
  if ![exit_codes.length] {
    error "If there is nothing in this array, that's wrong.";
  } {
    if exists(exit_codes.has_value.where{_}) {
      error "Process exited non-zero";
    } {
      "OK"
    }
  }
}

#{{{

let all_ok results {
  if ![results.length] {
    error "Process didn't return any results; this if weird itself";
  } {
    if (let failures = results.where(_.exit_code())) {
      let err_report = failures.map($<<"
        Command: $(res.command().join(' '))
        Exit code: $[res.exit_code]
      ").join('');
      say err_report;
      exit 255;
    }
  }
}

results.push ? pg_dump @args;

let r = ? shell.run $command @args;

if exists(let val = r.val) {
  say "Output:\n$(val)";
} else {
  let cmd = r.command();
  let ec = r.exit_code();
  say "Error running: $(cmd.join(' ')): code $(ec)";
}


}}}#

declare -a STATUS

# Past this point, we don't want to stop on failed commands,
# because having backups of some databases is better than 
# having backups of no databases.
set +e

function check_all_success()
{
	ARRAY=("${@}")

	# If there is nothing in this array, that's wrong.
	if [[ ${#ARRAY[@]} -eq 0 ]]; then
		return 1
	fi

	for val in "${ARRAY[@]}"; do 
		# Nonzero return code is an error.
		if [[ $val -gt 0 ]]; then
			return 1
		fi
	done
	# If we get here, all should be well.
	return 0
}

# $PGHOST is already double-quoted above. Additional double quoting changes the behavior
# Suppressions for shellcheck added accordingly.
C
# Back Up Each Database in compressed format.

let var results = ();

if !weekly_only {
  let db_names =
    psql -U $pg_user template1 @pg_host -p $pg_port @psql_flags
      -c "SELECT datname FROM pg_database WHERE datistemplate IS FALSE;";
  foreach db_name db_names {
    let pg_file = "$(backup_dir)/"
      ++ "$(servername)_$(db_name)_$(pg_port)_$(date_stamp).sqlc";
    fs.path(let checksum_file = "$(pg_file).checksum").ensure_rm();
    results.push exit_code pg_dump -U $pg_user @pg_host -p $pg_port
      $db_name @pg_dump_flags;
    os_bits.md5 $pg_file >$checksum_file;

	# Back Up The Globals.
	PGGLOBALS="${BACKUPDIR}/${SERVERNAME}_globals_${PGPORT}_${DATESTAMP}.sql"
	# Clean up the previous checksum file
	rm -vf "${PGGLOBALS}.checksum"
	# shellcheck disable=SC2086
	$PGDUMPALL -U $PGUSER $PGHOST -p $PGPORT "$PGDUMPALL_FLAGS" > "$PGGLOBALS"
	RETVAL=$?
	STATUS=("${STATUS[@]}" "$RETVAL")
	"$MD5" $MD5FLAGS "$PGGLOBALS" >| "${PGGLOBALS}.checksum"
fi

# Take a weekly backup of each DB if needed.
if [[ $WEEKLY == true ]] && [[ $DATESTAMP == "$WEEKLYDAY" ]]; then
	# shellcheck disable=SC2086 
	for DATNAME in $($PSQL -U $PGUSER template1 $PGHOST -p $PGPORT ${PSQL_FLAGS} -c "SELECT datname FROM pg_database WHERE datistemplate IS FALSE;"); do
		PGFILE="${BACKUPDIR}/${SERVERNAME}_${DATNAME}_${PGPORT}_${WEEKSTAMP}.sqlc"
		# Clean up the previous checksum file
		rm -vf "${PGFILE}.checksum"
		# shellcheck disable=SC2086 
		$PGDUMP -U $PGUSER $PGHOST -p $PGPORT "$DATNAME" "$PGDUMP_FLAGS" -f "$PGFILE"
		RETVAL=$?
		STATUS=("${STATUS[@]}" "$RETVAL")
		"$MD5" $MD5FLAGS "$PGFILE" >| "${PGFILE}.checksum"
	done
	# Back Up The Globals.
	PGGLOBALS="${BACKUPDIR}/${SERVERNAME}_globals_${PGPORT}_${WEEKSTAMP}.sql"
	# shellcheck disable=SC2086
	$PGDUMPALL -U $PGUSER $PGHOST -p $PGPORT "$PGDUMPALL_FLAGS" > "$PGGLOBALS"
	RETVAL=$?
	STATUS=("${STATUS[@]}" "$RETVAL")
	"$MD5" $MD5FLAGS "$PGGLOBALS" >| "${PGGLOBALS}.checksum"
fi

# We only delete if everything returned successfully.
check_all_success "${STATUS[@]}"
ALLOK=$?

# For deletion, we actually want shell expansion, so we don't double-quote the full rm command

# Delete yesterday's backups.
if [[ $ALLOK -eq 0 ]] && [[ $ONEDAY == true ]]; then
	# shellcheck disable=SC2086
	rm -vf ${BACKUPDIR}/*${YESTERDAY}*
fi

# Delete weekly backups on the one-week day.
# On the weekly backup day, we double-check that it finished before deleting it.
# If it isn't the weekly backup day, we delete because the backup, by default,
# should have been picked up in the last six days and moved off the server.
if ( [[ $ALLOK -eq 0 ]] && [[ $WEEKLYDAY == "$TODAY" ]] && [[ $ONEWEEK == true ]] && [[ $WEEKLYDELETEDAY == "$TODAY" ]] ) || \
	( [[ $ONEWEEK == true ]] && [[ $WEEKLYDAY != "$TODAY" ]] && [[ $WEEKLYDELETEDAY == "$TODAY" ]] ) ; then
	# shellcheck disable=SC2086
	rm -vf ${BACKUPDIR}/*${LASTWEEK}*
fi
