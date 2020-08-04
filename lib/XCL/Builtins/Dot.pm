package XCL::Builtins::Dot;

use XCL::V::Scope;
use XCL::Class -strict;

async sub dot_flip ($class, $scope, $lst) {
  return Err [ Name('WRONG_ARG_COUNT') => Int(0) ] unless $lst->values;
  my ($arg, $inv) = $lst->values;
  if (my $invoke = $arg->can_invoke or $arg->is('Name')) {
   return Val Curry [
      Native({ ns => $class, native_name => 'dot_curried' }),
      $invoke ? List[ Escape($arg), $inv ] : $lst
   ];
  }
  return await $class->c_fx_dot($scope, List [ $inv, $arg ]);
}

async sub dot_curried ($class, $scope, $lst) {
  return Err [ Name('WRONG_ARG_COUNT') => Int(0) ] unless $lst->values;
  my ($curried, $inv, @extra_args) = $lst->values;
  my ($name, @args) = $curried->values;
  return $_ for not_ok my $mres = await $class->c_fx_dot(
    $scope, List [ $inv, $name, @args ]
  );
  return await $scope->combine($mres->val, List \@extra_args);
}

async sub _expand_dot_rhs ($class, $scope, $rp) {
  return Val $rp if $rp->is('Name');
  return $_ for not_ok my $res = await $scope->eval_concat($rp);
  return $res;
}

# dot / .
async sub c_fx_dot ($class, $scope, $lst) {

  return Err [ Name('WRONG_ARG_COUNT') => Int(0) ]
    unless my @p = $lst->values;

  return $_ for not_ok
    my $rres = await $class->_expand_dot_rhs($scope, $p[0+!!$#p]);

  my $rhs = $rres->val;

  unless (@p > 1) {
    return Val Curry[
      Native({ ns => $class, native_name => 'dot_flip' }),
      $rhs
    ];
  }

  return $_ for not_ok
    my $lpres = await List([ $p[0] ])->f_expand($scope, List[]);
  my ($lhs_p, @rest) = $lpres->val->values;

  push @rest, @p[2..$#p];

  return $_ for not_ok my $lres = await $scope->eval_start($lhs_p);

  my $lhs = $lres->val;

  if ($rhs->can_invoke) {
    return Val Curry[ $rhs, $lhs, @rest ];
  }

  unless ($rhs->is('Name')) {
    return await $scope->combine($lhs, List[$rhs, @rest]);
  }

  return $_ for not_ok
    my $res = await $scope->lookup_method_of($lhs, $rhs->data);

  return Val Curry[ $res->val, Escape($lhs), @rest ];
}

async sub dot_assign_via_call ($class, $scope, $lst) {
  my $arg_count = my ($lhs_p, $rhs_p) = $lst->head->values;
  return Err [ Name('MISMATCH') ] unless $arg_count > 1;

  return $_ for not_ok
    my $rres = await $class->_expand_dot_rhs($scope, $rhs_p);

  my $rhs = $rres->val;

  return Err [ Name('MISMATCH') ] if $rhs->is('Name') or $rhs->can_invoke;

  return $_ for not_ok my $lres = await $scope->eval_concat(List[ $lhs_p ]);
  my ($lhs, @rest) = $lres->val->values;

  return await $scope->invoke_method_of(
    Escape(Call([ $lhs, $rhs ])), assign => $lst->tail
  );
}

sub metadata_for_c_fx_dot ($class) {
  return +{
    has_methods => Dict +{
      assign_via_call => Native({
        ns => $class,
        native_name => 'dot_assign_via_call',
        unwrap => 1,
      })
    },
  };
}

1;
