package XCL::V::Escape;

use XCL::Class 'XCL::V';

sub evaluate_against ($self, $scope) {
  ValF $self->data;
}

sub c_fx_make ($class, $lst) {
  ValF $class->of_data($lst->data->[0]);
}

1;
