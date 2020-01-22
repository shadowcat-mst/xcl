package XCL::V::Var;

use curry;
use XCL::Class 'XCL::V';

sub set_data ($self, $new) { $self->data($new); ValF($new) }

sub invoke ($self, $, $) {
  ResultF({
    val => $self->data,
    set => $self->curry::weak::set_data
  });
}

sub display ($self, $depth) {
  'Var('.$self->data->display($depth).')'
}

1;
