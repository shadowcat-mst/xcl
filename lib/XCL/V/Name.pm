package XCL::V::Name;

use XCL::Class 'XCL::V';

sub evaluate_against ($self, $scope) { $scope->get($self->data) }

sub display_data ($self, $) { $self->data }

sub f_name_to_string ($self, $) {
  ValF(String($self->data));
}

sub fx_assign ($self, $scope, $lst) {
  return $scope->set($self->data, $lst->head);
}

1;
