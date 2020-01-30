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
  Native
  Scope Block
  Compound Lambda
);

our @EXPORT = (
  @Types,
  qw(ResultF Val ValF Err ErrF),
  qw(not_ok not_ok_except),
  qw(DEBUG $Eval_Depth $Did_Thing),
);

our $Eval_Depth = -1;
our $Did_Thing;

use constant DEBUG => 0+!!$ENV{XCL_DEBUG};

foreach my $type (@Types) {
  my $class = "XCL::V::${type}";
  my $file = "XCL/V/${type}.pm";
  monkey_patch __PACKAGE__, $type, sub ($data, $metadata = {}) {
    require $file;
    $class->new(data => $data, metadata => $metadata);
  }
}

sub Val ($val, $metadata = {}) { Result({ val => $val }, $metadata) }
sub Err ($err, $metadata = {}) {
  my %meta = do {
    my ($pkg, $file, $line) = caller;
    (thrown_at => Dict({
      native_file => String($file), native_line => Int($line),
      map +($_ => $metadata->{$_}), grep $metadata->{$_}, 'caller',
    }));
  };
  Result({ err => Call($err) }, { %$metadata, %meta });
}

sub not_ok (@things) { grep !$_->is_ok, @things }

sub not_ok_except ($or, @things) {
  grep +(!$_->is_ok and !$_->err->data->[0]->data eq $or), @things
}

async sub ResultF {
  if ($_[0]->$_isa('XCL::V::Result')) {
    return $_[0];
  } else {
    die $_[0];
  }
}

sub ValF { ResultF(Val(@_)) }
sub ErrF { ResultF(Err(@_)) }

1;
