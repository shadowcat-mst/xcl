package XCL::Builtins;

use XCL::V::Scope;
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

async sub c_fx_if {
  my ($class, $scope, $lst) = @_;
  my ($cond, $true, $false) = @{$lst->data};
  my $dscope = $scope->derive;
  my $res = await $cond->evaluate_against($dscope);
  return $res unless $res->is_ok;
  my $bool = $res->val->bool;
  return $bool unless $bool->is_ok;
  if ($bool->val->data) {
    my $res = await $true->invoke($dscope);
    return defined($false) ? $res : Val($res);
  }
  return await $false->invoke($dscope) if $false;
  return Val(Err([ Name('NO_SUCH_VALUE') => String('else') ]));
}

async sub c_fx_while {
  my ($class, $scope, $lst) = @_;
  my ($cond, $body) = $lst->values;
  my $dscope = $scope->derive;
  my $did;
  WHILE: while (1) {
    my $res = await $cond->evaluate_against($dscope);
    return $res unless $res->is_ok;
    my $bool = $res->val->bool;
    return $bool unless $bool->is_ok;
    if ($bool->val->data) {
      $did ||= 1;
      my $bscope = $dscope->derive;
      my $res = await $body->invoke($bscope);
      return $res unless $res->is_ok;
    } else {
      last WHILE;
    }
  }
  return Val(Bool($did));
}

sub c_fx_escape ($class, $scope, $lst) { ValF $lst->data->[0] }

1;
