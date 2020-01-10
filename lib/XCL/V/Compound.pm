package XCL::V::Compound;

use Mojo::Base 'XCL::V', -async, -signatures;

async sub evaluate_against {
  my ($self, $scope) = @_;
  my ($val, @rest) = @{$self->data};
  my $res = await $scope->eval($val);
  return $res unless $res->is_ok;
  foreach my $step (@rest) {
    $res = await $res->val->invoke($scope, $step);
    return $res unless $res->is_ok;
  }
  return $res;
}

1;
