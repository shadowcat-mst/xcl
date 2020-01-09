package XCL::Builtins;

use XCL::Values;
use Mojo::Base -base, -signatures, -async;

async sub c_fx_set {
  my ($class, $scope, $lst) = @_;
  my ($set, $valproto) = $lst->values;
  my $pres = await $set->evaluate_against($scope);
  return $pres unless $pres->is_ok;
  my $place = $pres->val;
  return Err([ Name('NOT_SETTABLE') => String('FIXME') ])
    unless $place->can_set;
  my $valres = await $valproto->evaluate_against($scope);
  return $valres unless $valres->is_ok;
  return $place->set($valres->val);
}

sub c_fx_id ($class, $scope, $thing) {
  $thing->evaluate_against($scope);
}

1;
