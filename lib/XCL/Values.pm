package XCL::Values;

use strictures 2;
use curry;
use Exporter 'import';
use experimental 'signatures';

# string, bytes
# float, int
# name, bool
# list, dict
# call, block

sub _list ($env, @args) {
  my @ret;
  foreach my $arg (@args) {
    my $r = $arg->eval($env);
    return $r unless $r->is_ok;
    push @ret, $r->val;
  }
  return Val(List(\@ret));
}

our @Types = qw(
  String Bytes Float Int
  Bool Fexpr Dict List Name Call
  Result Var
  Native
  Environment
  Compound Lambda
);

our @EXPORT = (@Types, qw(Val Err _list));

foreach my $type (@Types) {
  my $class = "XCL::V::${type}";
  {
    no strict 'refs';
    *{$type} = sub ($data, $metadata = {}) {
      bless({ data => $data, metadata => $metadata }, $class);
    }
  }
}

sub Val ($val, $metadata = {}) { Result({ val => $val }, $metadata) }
sub Err ($err, $metadata = {}) {
  Result({ err => Call(List($err)) }, $metadata);
}

unless ($XCL::V::Loading) {
  local $INC{'XCL/Values.pm'} = __FILE__;
  require XCL::V
}

1;
