package XCL::V::Name;

use XCL::Class 'XCL::V';

sub evaluate_against ($self, $scope) { $scope->get($self->data) }

sub display_data ($self, $) { $self->data }

sub f_name_to_string ($self, $) {
  ValF(String($self->data));
}

async sub fx_assign ($self, $scope, $lst) {
  return $_ for not_ok_except INTRO_REQUIRES_SET =>
     my $res = await $scope->get_place($self->data);
  return await dot_call($scope, $res, assign => $lst->values);
}

1;
