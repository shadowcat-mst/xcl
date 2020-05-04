package XCL::V::Var;

use curry;
use XCL::Class 'XCL::V';

sub set_data ($self, $new) { $self->data($new); ValF($new) }

sub _invoke ($self, $, $) {
  ValF($self->data);
}

sub display_data ($self, $depth) {
  'Var('.$self->data->display($depth).')'
}

sub fx_assign_via_call ($self, $scope, $lst) {
  return ErrF [ Name('MISMATCH') ] unless my $val = $lst->tail->head;
  return $self->set_data($val);
}

1;
