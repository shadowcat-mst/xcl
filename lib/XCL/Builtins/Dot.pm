package XCL::Builtins::Dot;

use XCL::V::Scope;
use XCL::Class -strict;

async sub dot_flip ($class, $scope, $lst) {
  return Err [ Name('WRONG_ARG_COUNT') => Int(0) ] unless $lst->values;
  my ($arg, $inv) = $lst->values;
  if (my $invoke = $arg->can_invoke or $arg->is('Name')) {
   return Val Call [
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
  return await $mres->val->invoke($scope, List \@extra_args);
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

  return $_ for not_ok
    my $rres = await $class->_expand_dot_rhs($scope, $p[0+!!$#p]);

  my $rhs = $rres->val;

  unless (@p > 1) {
    return Val Call [
      Native({ ns => $class, native_name => 'dot_flip' }),
      $rhs
    ];
  }

  return $_ for not_ok my $lres = await $scope->eval(List[ $p[0] ]);
  my ($lhs, @rest) = $lres->val->values;

  push @rest, @p[2..$#p];

  if ($rhs->can_invoke) {
    return Val Call [ Escape($rhs), $lhs, @rest ];
  }

  unless ($rhs->is('Name')) {
    return await $lhs->invoke($scope, List[$rhs, @rest]);
  }

  my $name = String($rhs->data);

  my $fallthrough = !(my $has_methods = $lhs->metadata->{has_methods});

  if ($has_methods) {
    return $_ for not_ok_except NO_SUCH_VALUE =>
      my $res = await $has_methods->invoke($scope, List [ $name ]);
    return Val Call [ Escape($res->val), Escape($lhs), @rest ] if $res->is_ok;
  }

  my $nope = Err [ Name('NO_SUCH_METHOD_OF'), $name, $p[0] ];

  return $nope
    unless my $try =
      $lhs->metadata->{dot_via}
        || ($fallthrough && Name($lhs->type));

  return $_ for not_ok my $tres = await $scope->eval($try);

  return $nope
    unless my $via_methods = $tres->val->metadata->{provides_methods};

  return $_ for not_ok_except NO_SUCH_VALUE =>
    my $res = await $via_methods->invoke($scope, List [ $name ]);

  return $nope unless $res->is_ok;

  return Val Call [ Escape($res->val), Escape($lhs), @rest ];
}

async sub dot_assign_via_call ($class, $scope, $lst) {
  my $arg_count = my ($lhs_p, $rhs_p) = $lst->head->values;
  return Err [ Name('MISMATCH') ] unless $arg_count > 1;

  return $_ for not_ok
    my $rres = await $class->_expand_dot_rhs($scope, $rhs_p);

  my $rhs = $rres->val;

  return Err [ Name('DECLINE_MATCH') ] if $rhs->is('Name') or $rhs->can_invoke;

  return $_ for not_ok my $lres = await $scope->eval(List[ $lhs_p ]);
  my ($lhs, @rest) = $lres->val->values;

  return await dot_call_escape(
    $scope, Call([ $lhs, $rhs ]), assign => $lst->tail->values
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