package XCL::V::Compound;

use List::Util qw(reduce);
use XCL::Class 'XCL::V';

async sub evaluate_against ($self, $scope) {
  my ($val, @rest) = @{$self->data};
  while (@rest) {
    return $_ for not_ok my $res = await $scope->eval_concat($val);
    my $step = shift @rest;
    $val = Call[ Escape($res->val), $step->is('List') ? $step->values : $step ];
  }
  return await $scope->eval_raw($val);
}

sub display_data ($self, $depth) {
  join '', map $_->display($depth), @{$self->data};
}

sub f_list ($self, $) {
  ValF List $self->data;
}

async sub fx_assign ($self, $scope, $lst) {
  my ($val, @rest) = @{$self->data};
  my $res = await $scope->eval_concat($val);
  return $res unless $res->is_ok;
  # unsure: do we need an assign_via_compound as well?
  while (my $step = shift @rest) {
    my $step_list = $step->is('List') ? $step : List [$step];
    unless (@rest) {
      return $_ for not_ok_except NO_SUCH_METHOD_OF =>
        my $lres = await $scope->lookup_method_of($res->val, 'assign_via_call');
      if ($lres->is_ok) {
        return $_ for not_ok_except MISMATCH =>
          my $ares = await $scope->combine(
            $lres->val, List[$res->val, $step_list, $lst->values]
          );
        return $ares if $res->is_ok;
      }
    }
    return $_ for not_ok $res = await $scope->combine($res->val, $step_list);
  }
  return await $scope->invoke_method_of($res->val, assign => $lst);
}

sub to_call ($self) {
  return reduce {
    Call[ $a, $b->is('List') ? $b->values : $b ]
  } @{$self->data};
}

sub f_to_call ($self, $) {
  return ValF $self->to_call;
}

1;
