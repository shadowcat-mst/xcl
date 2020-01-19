package XCL::Builtins::Test;

use Test2::V0;
use XCL::Class -strict;

async sub c_fx_ok ($class, $scope, $lst) {
  my ($check, $strp) = $lst->values;
  my ($cval) = map { $_->val // return $_ } await $scope->eval($check);
  my ($bval) = map { $_->val // return $_ } await $cval->bool;
  my ($str) = (
    $strp
      ? map { $_->val // return $_ } await $scope->eval($strp)
      : $check->display
  );
  ok($bval->data, $str);
  return Val $bval;
}

sub c_f_done_testing ($class, $lst) { done_testing; Val Bool 1 }

1;
