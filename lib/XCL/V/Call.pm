package XCL::V::Call;

use Role::Tiny::With;
use XCL::Class 'XCL::V';

with 'XCL::V::Role::Listish';

sub evaluate_against ($self, $scope) {
  $self->_call($scope, @{$self->data});
}

sub _invoke ($self, $scope, $lst) {
  $self->_call($scope, @{$self->data}, $lst->values);
}

async sub _call ($self, $scope, $command_p, @args) {
  return $_ for not_ok my $res = await $scope->eval(List[$command_p]);
  my ($command, @rest) = $res->val->values;
  return await $command->invoke($scope, List[ @rest, @args ]);
}

sub display_data ($self, $depth) {
  return $self->SUPER::display_data(0) unless $depth;
  my $in_depth = $depth - 1;
  my @res;
  foreach my $val (@{$self->data}) {
    push @res, $val->display($in_depth);
  }
  return '[ '.join(' ', @res).' ]';
}

sub f_to_list ($self, $) {
  ValF List[ $self->values ];
}

async sub fx_assign ($self, $scope, $lst) {
  my ($head, $tail) = $self->ht;
  return $_ for not_ok my $res = await $scope->eval(List[$head]);
  my ($command, @rest) = $res->val->values;
  return $_ for not_ok_except NO_SUCH_VALUE =>
    my $lres = await dot_lookup($scope, $command, 'assign_via_call');
  if ($lres->is_ok) {
    return await $lres->val->invoke(
      $scope, List[List([@rest, $tail->values]), $lst->values]
    );
  }
  return $_ for not_ok
    my $cres = await $command->invoke($scope, List \@rest);
  return await dot_call_escape($scope, $cres->val, assign => $lst->values);
}

sub to_call ($self) { $self }

sub f_to_call ($self, $) { ValF $self }

1;
