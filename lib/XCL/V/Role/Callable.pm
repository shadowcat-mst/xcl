package XCL::V::Role::Callable;

use Mojo::Base -roles, -async;

async sub c_fx_make {
  my ($class, $scope, $lst) = @_;
  my ($argspec, $body_proto) = $lst->values;
  my $res = await $body_proto->eval_against($scope);
  return $res unless $res->is_ok;
  my @argnames = map $_->data, $argspec->values;
  Val($class->new(
    argnames => \@argnames,
    scope => $scope,
    body => $res->val,
  ));
}

1;
