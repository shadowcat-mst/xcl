package XCL::V::Escape;

use XCL::Class 'XCL::V';

sub evaluate_against ($self, $scope) {
  Future->done(Val($self->data))
}

sub c_fx_make ($class, $lst) {
  ValF $lst->data->[0];
}

1;
