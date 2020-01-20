package XCL::Builtins::Functions;

use XCL::V::Scope;
use XCL::Class -strict;

async sub c_fx_set {
  my ($class, $scope, $lst) = @_;
  my ($set, $valproto) = $lst->values;
  my $pres = await $scope->eval($set);
  return $pres unless $pres->is_ok;
  my $place = $pres->val;
  return Err([ Name('NOT_SETTABLE') => String('FIXME') ])
    unless $place->can_set;
  my $valres = await $scope->eval($valproto);
  return $valres unless $valres->is_ok;
  return $place->set($valres->val);
}

sub c_fx_id ($class, $scope, $lst) {
  my @values = $lst->values;
  return ResultF $scope->eval($values[0]) if @values == 1;
  return ResultF $scope->eval(Call(\@values));
}

sub c_fx_escape ($class, $scope, $lst) { ValF $lst->data->[0] }

sub c_fx_result_of ($class, $scope, $lst) {
   ValF $class->c_fx_id($scope, $lst)->get;
}

async sub c_fx_if {
  my ($class, $scope, $lst) = @_;
  my ($cond, $block, $dscope) = @{$lst->data};
  $dscope ||= $scope->snapshot;
  my $res = await $dscope->eval($cond);
  return $res unless $res->is_ok;
  my $boolp = await $res->val->bool;
  return $boolp unless $boolp->is_ok;
  my $bool = $boolp->val;
  if ($bool->data) {
    my $res = await $block->invoke($dscope);
    return $res unless $res->is_ok;
  }
  return ValF($bool);
}

async sub c_fx_unless {
  my ($class, $scope, $lst) = @_;
  my ($cond, $block) = @{$lst->data};
  my $res = await $scope->eval($cond);
  return $res unless $res->is_ok;
  my $boolp = await $res->val->bool;
  return $boolp unless $boolp->is_ok;
  my $bool = $boolp->val;
  unless ($bool->data) {
    my $res = await $block->invoke($scope);
    return $res unless $res->is_ok;
  }
  return ValF(Bool(0+!!$bool->data));
}

async sub c_fx_while {
  my ($class, $scope, $lst) = @_;
  my ($cond, $body, $dscope) = $lst->values;
  $dscope ||= $scope->snapshot;
  my $did = 0;
  WHILE: while (1) {
    my $res = await $dscope->eval($cond);
    return $res unless $res->is_ok;
    my $bool = await $res->val->bool;
    return $bool unless $bool->is_ok;
    if ($bool->val->data) {
      $did = 1;
      my $bscope = $dscope->derive;
      my $res = await $body->invoke($bscope);
      return $res unless $res->is_ok;
    } else {
      last WHILE;
    }
  }
  return Val Bool $did;
}

async sub c_fx_else {
  my ($class, $scope, $lst) = @_;
  my ($lp, $rp) = $lst->values;
  my $dscope = $scope->snapshot;
  my $lr = await $lp->invoke($scope, $dscope);
  return $lr unless $lr->is_ok;
  my $bres = await $lr->val->bool;
  return $bres unless $bres->is_ok;
  return $bres if $bres->val->data;
  my $else_res = await $rp->invoke($dscope);
  return $else_res unless $else_res->is_ok;
  return await $else_res->val->bool;
}

sub c_fx_do ($class, $scope, $lst) {
  $scope->eval(Call([ $lst->values ]));
}

async sub _dot_rhs_to_name {
  my ($class, $scope, $rp) = @_;
  if ($rp->is('Name')) {
    return Val String $rp->data;
  }
  my $res = await $scope->eval($rp);
  return $res unless $res->is_ok;
  return Err([ Name('WRONG_TYPE') ]) unless $res->val->is('String');
  return $res;
}

async sub c_fx_dot {
  my ($class, $scope, $lst) = @_;
  my ($lp, $rp) = $lst->values;
  unless (defined $rp) {
    my $name_r = await $class->_dot_rhs_to_name($scope, $lp);
    return $name_r unless $name_r->is_ok;
    my $name = $name_r->val;
    return Val Native async sub {
      my ($scope, $lst) = @_;
      my $lres = await $scope->eval($lst);
      return $lres unless $lres->is_ok;
      my ($inv, @args) = $lres->val->values;
      my $mres = await $class->c_fx_dot($scope, List([ $inv, $name ]));
      return $mres unless $mres->is_ok;
      return await $mres->invoke($scope, @args);
    };
  }
  my $lr = await $scope->eval($lp);
  return $lr unless $lr->is_ok;
  my $method_name = do {
    my $res = await $class->_dot_rhs_to_name($scope, $rp);
    return $res unless $res->is_ok;
    $res->val;
  };
  my $l = $lr->val;
  my $res;
  # let meta = metadata(l);
  # if [exists let dm = meta('dot_methods')] {
  #   if [exists let m = dm(r)] {
  #     m ++ (l)
  #   } {
  #     meta('dot_via')(r) ++ (l);
  #   }
  # } {
  #   if [exists let dv = meta('dot_via')] {
  #     scope.eval(dv.r) ++ (l);
  #   } {
  #     let sym = Name.make l.type();
  #     scope.eval(sym.r) ++ (l);
  #   }
  # }
  if (my $methods = $l->metadata->{dot_methods}) {
    $res = await $methods->invoke($scope, $method_name);
    if (!$res->is_ok and $res->err->data->[0]->data ne 'NO_SUCH_VALUE') {
      return $res;
    }
  }
  unless ($res and $res->is_ok) {
    # only fall back to the object type by default in absence of dot_methods
    if (my $dot_via = $l->metadata->{dot_via} || ($res and Name($l->type))) {
      $res = await $scope->eval(Call([
        Name('.'), $dot_via, $method_name
      ]));
      return $res unless $res->is_ok;
    }
  }
  return Err [ Name 'NO_SUCH_VALUE' ] unless $res;
  return Val Call [ $res->val, $l ];
}

sub c_f_metadata ($class, $lst) {
  Dict($lst->[0]->metadata);
}

1;
