package XCL::V::Var;

use curry;
use XCL::Class 'XCL::V';

sub set_data ($self, $new) { $self->data($new); ValF($new) }

sub _invoke ($self, $, $) {
  ResultF(Result {
    val => $self->data,
    set => $self->curry::weak::set_data
  });
}

sub display_data ($self, $depth) {
  'Var('.$self->data->display($depth).')'
}

sub fx_assign ($self, $lst) {
  return $self->set_data($lst->values);
}

1;
