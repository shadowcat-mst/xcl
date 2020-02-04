package XCL::Builtins::Functions;

use XCL::V::Scope;
use XCL::Class -strict;

# set / =
async sub c_fx_set {
  my ($class, $scope, $lst) = @_;
  my ($set, $valproto) = $lst->values;
  my $place = await $scope->eval($set);
  return Err [ Name('NOT_SETTABLE') => String('FIXME') ]
    unless $place->can_set_value;
  return $_ for not_ok my $valres = await $scope->eval($valproto);
  return await $place->set_value($valres->val);
}

# id / $
sub c_fx_id ($class, $scope, $lst) {
  my @values = $lst->values;
  return $scope->eval($values[0]) if @values == 1;
  return $scope->eval(Call(\@values));
}

# do
sub c_fx_do ($class, $scope, $lst) {
  $scope->eval(Call([ $lst->values ]));
}

# escape / \
sub c_fx_escape ($class, $scope, $lst) { ValF $lst->data->[0] }

# result_of / ?
async sub c_fx_result_of {
  my ($class, $scope, $lst) = @_;
  Val $class->c_fx_id($scope, $lst);
}

async sub c_fx_if {
  my ($class, $scope, $lst) = @_;
  my ($cond, $block, $dscope) = @{$lst->data};
  $dscope ||= $scope->snapshot;
  return $_ for not_ok my $res = await $dscope->eval($cond);
  return $_ for not_ok my $bres = await $res->val->bool;
  if ($bres->val->data) {
    return $_ for not_ok await $block->invoke($dscope);
  }
  return $bres;
}

async sub c_fx_unless {
  my ($class, $scope, $lst) = @_;
  my ($cond, $block) = @{$lst->data};
  return $_ for not_ok my $res = await $scope->eval($cond);
  return $_ for not_ok my $bres = await $res->val->bool;
  unless ($bres->val->data) {
    return $_ for not_ok await $block->invoke($scope);
  }
  return $bres;
}

# wutcol / ?:
async sub c_fx_wutcol {
  my ($class, $scope, $lst) = @_;
  my ($cond, @ans) = @{$lst->data};
  my ($then, $else) = (@ans > 1 ? @ans : (undef, @ans));
  return $_ for not_ok my $res = await $scope->eval($cond);
  return $_ for not_ok my $bres = await $res->val->bool;
  if ($bres->val->data) {
    return $res unless $then;
    return await $scope->eval($then);
  }
  return await $scope->eval($else);
}

async sub c_fx_while {
  my ($class, $scope, $lst) = @_;
  my ($cond, $body, $dscope) = $lst->values;
  $dscope ||= $scope->snapshot;
  my $did = 0;
  WHILE: while (1) {
    return $_ for not_ok my $res = await $dscope->eval($cond);
    return $_ for not_ok my $bres = await $res->val->bres;
    if ($bres->val->data) {
      $did = 1;
      my $bscope = $dscope->derive;
      return $_ for not_ok await $body->invoke($bscope);
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
  return $_ for not_ok my $lr = await $lp->invoke($scope, List $dscope);
  return $_ for not_ok my $bres = await $lr->val->bool;
  return $bres if $bres->val->data;
  return $_ for not_ok my $else_res = await $rp->invoke($dscope);
  return await $else_res->val->bool;
}

async sub _dot_rhs_to_string {
  my ($class, $scope, $rp) = @_;
  return Val $rp if $rp->is('String');
  return Val String $rp->data if $rp->is('Name');
  return $_ for not_ok my $res = await $scope->eval($rp);
  return Err([ Name('WRONG_TYPE') ]) unless $res->val->is('String');
  return $res;
}

async sub dot_name {
  my ($class, $scope, $lst) = @_;
  return Err [ Name('WRONG_ARG_COUNT') => Int(0) ] unless $lst->values;
  my ($name, $inv, @args) = $lst->values;
  return $_ for not_ok
    my $mres = await $class->c_fx_dot($scope, List [ $inv, $name ]);
  return await $mres->val->invoke($scope, List \@args);
}

# dot / .
async sub c_fx_dot {
  my ($class, $scope, $lst) = @_;

  return Err [ Name('WRONG_ARG_COUNT') => Int(0) ]
    unless my @p = $lst->values;

  my ($name) = (
    map { $_->is_ok ? $_->val : return $_ }
      await $class->_dot_rhs_to_string($scope, $p[-1])
  );

  unless (@p > 1) {
    return Val Call [
      Native({ ns => $class, native_name => 'dot_name', apply => 1 }),
      $name
    ];
  }

  my ($l) = map { $_->is_ok ? $_->val : return $_ } await $scope->eval($p[0]);

  my $fallthrough = !(my $dot_methods = $l->metadata->{dot_methods});

  if ($dot_methods) {
    return $_ for not_ok_except NO_SUCH_VALUE =>
      my $res = await $dot_methods->invoke($scope, List [ $name ]);
    return Val Call [ Escape($res->val), $l ] if $res->is_ok;
  }

  return Err [ Name('NO_SUCH_VALUE'), $name ]
    unless my $try =
      $l->metadata->{dot_via}
        || ($fallthrough && Name($l->type));
  return $_ for not_ok my $res = await $class->c_fx_dot(
    $scope, List [ $try, $name ]
  );

  return Val Call [ Escape($res->val), $l ];
}

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

# metadata / ^
sub c_f_metadata ($class, $lst) {
  Dict($lst->[0]->metadata);
}

1;
