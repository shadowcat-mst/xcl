package XCL::Values;

use XCL::Strand::Future;
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

our @EXPORT = (@Types, qw(ResultF Val ValF Err ErrF not_ok));

foreach my $type (@Types) {
  my $class = "XCL::V::${type}";
  my $file = "XCL/V/${type}.pm";
  {
    no strict 'refs';
    *{$type} = sub ($data, $metadata = {}) {
      require $file;
      $class->new(data => $data, metadata => $metadata);
    }
  }
}

sub Val ($val, $metadata = {}) { Result({ val => $val }, $metadata) }
sub Err ($err, $metadata = {}) {
  Result({ err => Call($err) }, $metadata);
}

sub not_ok (@things) {
  @things = ($_) unless @things;
  grep !$_->is_ok, @things;
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
