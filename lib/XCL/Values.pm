package XCL::Values;

use Mojo::Base -strict, -signatures, -async;
use Exporter 'import';

# string, bytes
# float, int
# name, bool
# list, dict
# call, block

async sub _list ($env, @args) {
  my @ret;
  foreach my $arg (@args) {
    my $r = await $arg->eval($env);
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
