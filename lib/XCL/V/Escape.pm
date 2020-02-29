package XCL::V::Escape;

use XCL::Class 'XCL::V';

sub evaluate_against ($self, $scope) {
  ValF $self->data;
}

sub c_fx_make ($class, $scope, $lst) {
  ValF $class->of_data($lst->data->[0]);
}

sub display_data ($self, $depth) {
  return $self->SUPER::display_data(0) unless $depth;
  my $in_depth = $depth - 1;
  return '\('.$self->data->display($in_depth).')';
}

1;
