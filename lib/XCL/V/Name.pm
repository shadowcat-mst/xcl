package XCL::V::Name;

use XCL::Values;
use Mojo::Base 'XCL::V', -signatures;

sub evaluate_against ($self, $scope) { $scope->get($self->data) }

sub display ($self, @) { $self->data }

sub f_name_to_string ($self, $) {
  ValF(String($self->data));
}

1;
