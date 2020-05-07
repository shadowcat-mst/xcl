package XCL::Builtins::Functions;

use Mojo::Util 'monkey_patch';
use XCL::V::Scope;
use XCL::Class -strict;

# id / $
sub c_fx_id ($class, $scope, $lst) { $scope->f_expr($lst) }

# do
sub c_fx_do ($class, $scope, $lst) { $scope->f_call($lst) }

# escape / \
sub c_fx_escape ($class, $scope, $lst) { ValF $lst->data->[0] }

async sub c_fx_result_of ($class, $scope, $lst) {
  Val await $scope->f_call($lst);
}

async sub c_fx_if ($class, $scope, $lst) {
  my ($cond, $block, $dscope) = @{$lst->data};
  $dscope ||= $scope->snapshot;
  return $_ for not_ok my $res = await $dscope->eval($cond);
  return $_ for not_ok my $bres = await $res->val->bool;
  if ($bres->val->data) {
    return $_ for not_ok +await $block->invoke($dscope, List []);
  }
  return $bres;
}

async sub c_fx_unless ($class, $scope, $lst) {
  my ($cond, $block) = @{$lst->data};
  return $_ for not_ok my $res = await $scope->eval($cond);
  return $_ for not_ok my $bres = await $res->val->bool;
  unless ($bres->val->data) {
    return $_ for not_ok +await $block->invoke($scope);
  }
  return $bres;
}

async sub c_fx_where ($class, $scope, $lst) {
  my ($cond, $block, $dscope) = @{$lst->data};
  $dscope ||= $scope->snapshot;
  return $_ for
    not_ok_except NO_SUCH_VALUE => my $res = await $dscope->eval($cond);
  return Val False unless $res->is_ok;
  return $_ for not_ok my $bres = await $res->val->bool;
  if ($bres->val->data) {
    return $_ for not_ok +await $block->invoke($dscope, List []);
  }
  return $bres;
}

# wutcol / ?:
async sub c_fx_wutcol ($class, $scope, $lst) {
  my ($cond, @ans) = $lst->values;
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
      return $_ for not_ok +await $body->invoke($bscope);
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

  my ($rhs) = (
    map { $_->is_ok ? $_->val : return $_ }
      await $class->_expand_dot_rhs($scope, $p[0+!!$#p])
  );

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

# metadata / ^
sub c_f_metadata ($class, $lst) {
  ValF Dict($lst->data->[0]->metadata);
}

# maybe
async sub c_fx_maybe ($class, $scope, $lst) {
  my $res = await $scope->f_expr($lst);
  return $_ for not_ok_except NO_SUCH_VALUE => $res;
  return Val List[ $res->is_ok ? ($res->val) : () ];
}

async sub c_fx_exists ($class, $scope, $lst) {
  return $_ for not_ok my $res = await $class->c_fx_maybe($scope, $lst);
  return Val Bool 0+!!$res->val->count;
}

async sub c_fx_exists_or ($class, $scope, $lst) {
  my ($exists, $or) = $lst->values;
  return $_ for not_ok
    my $res = await $class->c_fx_maybe($scope, List[$exists]);
  return Val($_) for $res->val->values;
  return await $scope->eval($or);
}

async sub c_fx_matches ($class, $scope, $lst) {
  my $res = await $scope->f_expr($lst);
  return $_ for not_ok_except MISMATCH => $res;
  return Val Bool $res->is_ok;
}

async sub c_fx_pair ($class, $scope, $lst) {
  my ($key_p, $val_p) = $lst->values;

  return Val Call [
    Native({ ns => $class, native_name => 'c_fx_pair' }),
    $key_p
  ], { is_pair_proto => True } unless $val_p;

  my $key = do {
    if ($key_p->is('Name')) {
      String($key_p->data);
    } else {
      return $_ for not_ok my $res = await $scope->eval($key_p);
      die "WHAT" unless (my $val = $res->val)->is('String');
      $val;
    }
  };
  return $_ for not_ok my $res = await $scope->eval($val_p);
  return Val List[ $key, $res->val ], { is_pair => True };
}

async sub c_fx_assign ($class, $scope, $lst) {
  my ($assign_to, $to_assign) = $lst->values;
  return Err [ Name('MISMATCH') ] unless $to_assign;
  return $_ for not_ok my $res = await $scope->eval($to_assign);
  await dot_call_escape($scope, $assign_to, assign => $res->val);
}

sub metadata_for_c_fx_assign ($class) {
  return +{
    has_methods => Dict +{
      assign_via_call => Native({
        ns => $class,
        native_name => 'assign_assign_via_call',
        unwrap => 1,
      })
    },
  };
}

async sub assign_assign_via_call ($class, $scope, $lst) {
  my ($args, $to_assign) = $lst->values;
  my ($assign_to, $default_to) = $args->values;
  return $_ for not_ok my $res = await $scope->eval($to_assign||$default_to);
  await dot_call_escape($scope, $assign_to, assign => $res->val);
}

{
  my %intro_as = (cur => undef, let => \&Val, var => \&Var);
  foreach my $type (sort keys %intro_as) {
    my $intro_as = $intro_as{$type};
    monkey_patch __PACKAGE__,
      "c_fx_${type}" => sub (@) {
        ErrF [ Name('VALID_ONLY_IN_ASSIGN') => Name($type) ];
      },
      "${type}_assign_via_call" => sub ($class, $scope, $lst) {
        my ($args, $to_assign) = $lst->values;
        return Err [ Name('MISMATCH') ] unless $to_assign;
        my ($assign_to) = $args->values;
        my $assign_scope = $scope->but(intro_as => $intro_as);
        dot_call_escape($assign_scope, $assign_to, assign => $to_assign);
      },
      "metadata_for_c_fx_${type}" => sub ($class) {
        return +{
          has_methods => Dict +{
            assign_via_call => Native({
              ns => $class,
              native_name => "${type}_assign_via_call",
              unwrap => 1
            })
          },
        };
      };
  }
}

sub metadata_for_alias_dict ($class) {
  return +{
    has_methods => Dict +{
      assign_via_call => Native({
        ns => Dict,
        native_name => 'destructure',
        unwrap => 1,
      })
    },
  };
}

1;
