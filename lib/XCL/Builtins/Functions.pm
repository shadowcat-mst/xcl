package XCL::Builtins::Functions;

use XCL::V::Scope;
use XCL::Class -strict;

# set / =
async sub c_fx_set ($class, $scope, $lst) {
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
async sub c_fx_result_of ($class, $scope, $lst) {
  Val $class->c_fx_id($scope, $lst);
}

async sub c_fx_if ($class, $scope, $lst) {
  my ($cond, $block, $dscope) = @{$lst->data};
  $dscope ||= $scope->snapshot;
  return $_ for not_ok my $res = await $dscope->eval($cond);
  return $_ for not_ok my $bres = await $res->val->bool;
  if ($bres->val->data) {
    return $_ for not_ok await $block->invoke($dscope, List []);
  }
  return $bres;
}

async sub c_fx_unless ($class, $scope, $lst) {
  my ($cond, $block) = @{$lst->data};
  return $_ for not_ok my $res = await $scope->eval($cond);
  return $_ for not_ok my $bres = await $res->val->bool;
  unless ($bres->val->data) {
    return $_ for not_ok await $block->invoke($scope);
  }
  return $bres;
}

# wutcol / ?:
async sub c_fx_wutcol ($class, $scope, $lst) {
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

async sub c_fx_while ($class, $scope, $lst) {
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

async sub c_fx_else ($class, $scope, $lst) {
  my ($lp, $rp) = $lst->values;
  my $dscope = $scope->snapshot;
  return $_ for not_ok my $lr = await $lp->invoke($scope, List $dscope);
  return $_ for not_ok my $bres = await $lr->val->bool;
  return $bres if $bres->val->data;
  return $_ for not_ok my $else_res = await $rp->invoke($dscope);
  return await $else_res->val->bool;
}

async sub dot_flip ($class, $scope, $lst) {
  return Err [ Name('WRONG_ARG_COUNT') => Int(0) ] unless $lst->values;
  if (($lst->values)[0]->is('Name')) {
   return Val Call [
      Native({ ns => $class, native_name => 'dot_curried' }),
      $lst
   ];
  }
  my ($arg, $inv) = $lst->values;
  return await $class->c_fx_dot($scope, List [ $inv, $arg ]);
}

async sub dot_curried ($class, $scope, $lst) {
  return Err [ Name('WRONG_ARG_COUNT') => Int(0) ] unless $lst->values;
  my ($curried, $inv, @extra_args) = $lst->values;
  my ($name, @args) = $curried->values;
  return $_ for not_ok my $mres = await $class->c_fx_dot(
    $scope, List [ $inv, $name ]
  );
  return await $mres->val->invoke($scope, List [ @args, @extra_args ]);
}

async sub dot_combi ($class, $scope, $lst) {
  my ($l, $r, @rest) = $lst->values;
  return $_ for not_ok my $lres = await $l->invoke($scope, List \@rest);
  return await $class->c_fx_dot($scope, List [ $lres->val, $r ]);
}

async sub _expand_dot_rhs ($class, $scope, $rp) {
  return Val $rp if $rp->is('Name');
  return $_ for not_ok my $res = await $scope->eval($rp);
  return $res;
}

# dot / .
async sub c_fx_dot ($class, $scope, $lst) {

  return Err [ Name('WRONG_ARG_COUNT') => Int(0) ]
    unless my @p = $lst->values;

  my ($rhs) = (
    map { $_->is_ok ? $_->val : return $_ }
      await $class->_expand_dot_rhs($scope, $p[-1])
  );

  unless (@p > 1) {
    return Val Call [
      Native({ ns => $class, native_name => 'dot_flip' }),
      $rhs
    ];
  }

  my ($lhs) = map { $_->is_ok ? $_->val : return $_ } await $scope->eval($p[0]);

  if ($lhs->is('Call') and (my $native = ($lhs->values)[0])->is('Native')) {
    my $m = $native->data;
    if (($m->{ns}||'') eq $class) {
      my $n = $m->{native_name};
      if ($n eq 'dot_flip' or $n eq 'dot_curried') {
        return Val Call [
          Native({ ns => $class, native_name => 'dot_combi' }),
          $lhs, $rhs
        ];
      }
    }
  }

  unless ($rhs->is('Name')) {
    return await $lhs->invoke($scope, List[$rhs]);
  }

  my $name = String($rhs->data);

  my $fallthrough = !(my $dot_methods = $lhs->metadata->{dot_methods});

  if ($dot_methods) {
    return $_ for not_ok_except NO_SUCH_VALUE =>
      my $res = await $dot_methods->invoke($scope, List [ $name ]);
    return Val Call [ Escape($res->val), Escape($lhs) ] if $res->is_ok;
  }

  return Err [ Name('NO_SUCH_METHOD_OF'), $name, $p[0] ]
    unless my $try =
      $lhs->metadata->{dot_via}
        || ($fallthrough && Name($lhs->type));
  return $_ for not_ok my $res = await $class->c_fx_dot(
    $scope, List [ $try, $rhs ]
  );

  return Val Call [ Escape($res->val), Escape($lhs) ];
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

# exists
async sub c_fx_exists ($class, $scope, $lst) {
  my $res = await (
    $lst->count > 1
      ? $scope->f_call($lst)
      : $scope->f_eval($lst)
  );
  return $_ for not_ok_except NO_SUCH_VALUE => $res;
  return Val List[ $res->is_ok ? ($res->val) : () ];
}

1;
