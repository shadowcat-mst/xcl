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

our @EXPORT = (@Types, qw(ResultF Val ValF Err ErrF));

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

sub ResultF {
  if ($_[0]->$_isa('XCL::V::Result')) {
    Future->done($_[0])
  } else {
    Future->fail(Result(@_))
  }
}

sub ValF { ResultF(Val(@_)) }
sub ErrF { ResultF(Err(@_)) }

1;
