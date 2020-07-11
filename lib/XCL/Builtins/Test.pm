package XCL::Builtins::Test;

use Test2::V0;
use XCL::Class -strict;

async sub c_fx_ok ($class, $scope, $lst) {
  my ($check, $strp) = $lst->values;
  return $_ for not_ok my $cres = await concat $scope->eval($check);
  return $_ for not_ok my $bres = await concat $cres->val->bool;
  my ($str) = do {
    if ($strp) {
      return $_ for not_ok my $sres = await concat $scope->eval($strp);
      return $_ for not_ok my $res = await concat $sres->val->string;
      $res->val->data;
    } else {
      $check->display(4)
    }
  };
  ok($bres->val->data, $str);
  return $bres;
}

async sub c_fx_is ($class, $scope, $lst) {
  my ($lp, $rp) = $lst->values;
  return $_ for not_ok my $lres = await concat $scope->eval($lst);
  my ($lv, $rv, $strp) = $lres->val->values;
  my ($str) = do {
    if ($strp) {
      return $_ for not_ok my $res = await concat $strp->string;
      $res->val->data;
    } else {
      join ' -> ', map $_->display(4), $lp, $rp;
    }
  };
  my ($ls, $rs) = map $_->display(-1), $lv, $rv;
  if ($ls eq $rs) {
    pass($str);
  } else {
    fail($str,
      "Evaluated: ".$lp->display(4)."\n"
     ."Result   : ".$ls."\n"
     ."Expected : ".$rs."\n"
    );
  }
  return Val Bool 0+!!($ls eq $rs);
}

async sub c_fx_todo ($class, $scope, $lst) {
  return $_ for not_ok my $lres = await concat $scope->eval($lst);
  my ($strp, $func) = $lres->val->values;
  return $_ for not_ok my $sres = await concat $strp->string;
  dynamically my $todo = todo $sres->val->data;
  return await concat $func->invoke($scope, List[]);
}

sub c_f_diag ($class, $lst) {
  diag($lst->display(8));
  return ValF True;
}

1;
