package XCL::Builtins::ControlFlow;

use XCL::Values;
use Mojo::Base -strict, -async;

async sub if {
  my ($scope, $lst) = @_;
  my ($cond, $true, $false) = @{$lst->data};
  my $dscope = $scope->derive;
  my $res = await $cond->evaluate_against($dscope);
  return $res unless $res->is_ok;
  my $bool = $res->val->bool;
  return $bool unless $bool->is_ok;
  if ($bool->val->data) {
    my $res = await $true->evaluate_against($dscope);
    return defined($false) ? $res : Val($res);
  }
  return await $false->evaluate_against($dscope) if $false;
  return Val(Err([ Name('NO_SUCH_VALUE') => String('else') ]));
}

async sub while {
  my ($scope, $lst) = @_;
  my ($cond, $body) = @{$lst->data};
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
      my $res = await $body->evaluate_against($bscope);
      return $res unless $res->is_ok;
    } else {
      last WHILE;
    }
  }
  return Val(Bool($did));
}

1;
