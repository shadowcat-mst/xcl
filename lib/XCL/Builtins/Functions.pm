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

# direct result return (no implicit return-on-err)
async sub c_fx_result_of ($class, $scope, $lst) {
  Val +await $scope->f_call($lst);
}

async sub c_fx_catch_only ($class, $scope, $lst) {
  my ($head, $tail) = $lst->ht;
  return $_ for
    not_ok_except $head->data, my $res = await $scope->f_expr($tail);
  return Val $res;
}

# metadata / ^
sub c_f_metadata ($class, $lst) {
  ValF Dict($lst->data->[0]->metadata);
}

# wutcol / ?:
async sub c_fx_wutcol ($class, $scope, $lst) {
  my ($cond, @ans) = $lst->values;
  my ($then, $else) = (@ans > 1 ? @ans : (undef, @ans));
  my $wres;
  return $_ for not_ok
    my $res = await $scope->eval_concat($cond)->then::_(sub ($r) {
      ($wres = $r)->bool;
  });
  if ($res->val->data) {
    return $then ? await $scope->eval_concat($then) : $wres;
  }
  return await $scope->eval_concat($else);
}

async sub c_fx_while ($class, $scope, $lst) {
  my ($cond, $body, $dscope) = $lst->values;
  $dscope ||= $scope->snapshot;
  my $did = 0;
  WHILE: while (1) {
    return $_ for not_ok my $bres = await $dscope->eval_drop($cond)->then::bool;
    if ($bres->val->data) {
      $did = 1;
      my $bscope = $dscope->derive;
      return $_ for not_ok +await $bscope->combine($body, List[]);
    } else {
      last WHILE;
    }
  }
  return Val Bool $did;
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
  return await $scope->eval_concat($or);
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
      return $_ for not_ok my $res = await $scope->eval_concat($key_p);
      die "WHAT" unless (my $val = $res->val)->is('String');
      $val;
    }
  };
  return $_ for not_ok my $res = await $scope->eval_concat($val_p);
  return Val List[ $key, $res->val ], { is_pair => True };
}

async sub c_fx_assign ($class, $scope, $lst) {
  my ($assign_to, $to_assign) = $lst->values;
  return Err [ Name('MISMATCH') ] unless $to_assign;
  return $_ for not_ok my $res = await $scope->eval_concat($to_assign);
  await $scope->invoke_method_of(Escape($assign_to), assign => List[$res->val]);
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
  return $_ for not_ok my $res = await $scope->eval_concat($to_assign||$default_to);
  await $scope->invoke_method_of(Escape($assign_to), assign => List[$res->val]);
}

{
  my %intro_as = (cur => undef, let => \&Val, var => \&Var);
  foreach my $type (sort keys %intro_as) {
    my $intro_as = $intro_as{$type};
    monkey_patch __PACKAGE__,
      "c_fx_${type}" => sub (@) {
        ErrF [ Name('VALID_ONLY_IN_ASSIGN') => Name($type) ];
      },
      "${type}_assign_via_call" => async sub ($class, $scope, $lst) {
        my ($args, $to_assign) = $lst->values;
        return ErrF [ Name('MISMATCH') ] unless $to_assign;
        my ($assign_to) = $args->values;
        return await $scope->but_intro_as($intro_as,
          $scope->curry::invoke_method_of(
            Escape($assign_to), assign => List[$to_assign]
          )
        );
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

async sub c_fx_sleep ($class, $scope, $lstp) {
  return $_ for not_ok my $lres = await $scope->eval_concat($lstp);
  my ($time) = $lres->val->values;
  await Mojo::Promise->timer($time->data);
  return Val True;
}

async sub c_fx_every ($class, $scope, $lstp) {
  return $_ for not_ok my $lres = await $scope->eval_concat($lstp);
  my ($time, $code) = $lres->val->values;
  my $tick = async sub {
    await Mojo::Promise->timer($time->data);
    return await $scope->combine($code, List[]);
  };
  Stream({
    generator => $tick,
  });
}

sub c_fx_no_such_value (@) {
  return ErrF [ Name('NO_SUCH_VALUE') ];
}

sub c_fx_start ($class, $scope, $lst) {
  my $inv = Call[ $lst->values ];
  return $scope->eval_start($inv);
}

1;
