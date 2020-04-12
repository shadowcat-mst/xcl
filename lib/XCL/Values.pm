package XCL::Values;

use XCL::Strand::Future;
use Mojo::Util qw(monkey_patch);
use XCL::Class -exporter;

# why?
use experimental 'signatures';
no warnings 'redefine';

# string, bytes
# float, int
# name, bool
# list, dict
# call, block

our @Types = qw(
  String Bytes Float Int Escape
  Bool Fexpr Dict List Name Call
  Result Var
  Native PerlObject
  Scope Block
  Compound Lambda
);

our @EXPORT = (
  @Types,
  qw(ResultF Val ValF Err ErrF),
  qw(not_ok not_ok_except),
  qw(DEBUG $Eval_Depth $Did_Thing $Am_Running),
  qw(True False),
);

our $Eval_Depth = -1;
our $Did_Thing;
our $Am_Running;

use constant DEBUG => $ENV{XCL_DEBUG} || 0;

foreach my $type (@Types) {
  my $class = "XCL::V::${type}";
  my $file = "XCL/V/${type}.pm";
  monkey_patch __PACKAGE__, $type, sub {
    return $class unless @_;
    my ($data, $metadata) = @_;
    require $file;
    $class->new(data => $data, metadata => $metadata||{});
  }
}

sub Val ($val, $metadata = {}) { Result({ val => $val }, $metadata) }
sub Err ($err, $metadata = {}, $l = 0) {
  my %meta = (%$metadata, do {
    my ($pkg, $file, $line) = caller($l);
    (
      thrown_at => Dict({
        native_file => String($file), native_line => Int($line),
        map +($_ => $metadata->{$_}), grep $metadata->{$_}, 'caller',
      }),
      err_at => List($Am_Running),
    );
  });
  Result({ err =>
    ref($err) eq 'ARRAY' ? Call($err, \%meta) : $err
  });
}

sub not_ok (@things) { grep !$_->is_ok, @things }

sub not_ok_except ($or, @things) {
  grep +(!$_->is_ok and not $_->err->data->[0]->data eq $or), @things
}

async sub ResultF {
  if ($_[0]->$_isa('XCL::V::Result')) {
    return $_[0];
  } else {
    die "ResultF called on non-result: $_[0]";
  }
}

sub ValF { ResultF(Val(@_)) }
sub ErrF ($err, $meta = {}) { ResultF(Err($err, $meta, 1)) }

sub True { Bool(1) }
sub False { Bool(0) }

1;
