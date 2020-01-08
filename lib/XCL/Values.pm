package XCL::Values;

use Mojo::Base -strict, -signatures, -async;
use Exporter 'import';

# string, bytes
# float, int
# name, bool
# list, dict
# call, block

async sub _list {
  my ($scope, @args) = @_;
  my @ret;
  foreach my $arg (@args) {
    my $res = await $arg->evaluate_against($scope);
    return $res unless $res->is_ok;
    push @ret, $res->val;
  }
  return Val(List(\@ret));
}

our @Types = qw(
  String Bytes Float Int
  Bool Fexpr Dict List Name Call
  Result Var
  Native
  Scope Block
  Compound Lambda
);

our @EXPORT = (@Types, qw(Val Err _list));

foreach my $type (@Types) {
  my $class = "XCL::V::${type}";
  my $file = "XCL/V/${type}.pm";
  {
    no strict 'refs';
    *{$type} = sub ($data, $metadata = {}) {
      require $file;
      bless({ data => $data, metadata => $metadata }, $class);
    }
  }
}

sub Val ($val, $metadata = {}) { Result({ val => $val }, $metadata) }
sub Err ($err, $metadata = {}) {
  Result({ err => Call(List($err)) }, $metadata);
}

1;
