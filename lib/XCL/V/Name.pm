package XCL::V::Name;

use XCL::Class 'XCL::V';

sub evaluate_against ($self, $scope) { $scope->get($self->data) }

sub display_data ($self, $) { $self->data }

sub f_name_to_string ($self, $) {
  ValF(String($self->data));
}

async sub fx_assign ($self, $scope, $lst) {
  return $_ for not_ok my $res = await $scope->get_place($self->data);
  return $_ for not_ok my $vres = await $scope->f_expr($lst);
  return await dot_call($scope, $res->val, assign => $vres->val);
}

1;
