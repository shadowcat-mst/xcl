package XCL::V::Compound;

use List::Util qw(reduce);
use XCL::Class 'XCL::V';

async sub evaluate_against ($self, $scope) {
  my ($val, @rest) = @{$self->data};
  my $res = await $scope->eval($val);
  return $res unless $res->is_ok;
  foreach my $step (@rest) {
    $res = await $scope->combine(
             $res->val, $step->is('List') ? $step : List[$step]
           );
    return $res unless $res->is_ok;
  }
  return $res;
}

sub display_data ($self, $depth) {
  join '', map $_->display($depth), @{$self->data};
}

sub f_list ($self, $) {
  ValF List $self->data;
}

async sub fx_assign ($self, $scope, $lst) {
  my ($val, @rest) = @{$self->data};
  my $res = await $scope->eval($val);
  return $res unless $res->is_ok;
  # unsure: do we need an assign_via_compound as well?
  while (my $step = shift @rest) {
    my $step_list = $step->is('List') ? $step : List [$step];
    unless (@rest) {
      return $_ for not_ok_except NO_SUCH_VALUE =>
        my $lres = await dot_lookup_escape(
          $scope, $res->val, 'assign_via_call'
        );
      if ($lres->is_ok) {
        return await $scope->combine(
          $lres->val, List[$step_list, $lst->values]
        );
      }
    }
    return $_ for not_ok $res = await $scope->combine($res->val, $step_list);
  }
  return await dot_call_escape($scope, $res->val, assign => $lst->values);
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
