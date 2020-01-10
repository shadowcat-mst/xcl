package XCL::V::Result;

use XCL::Values;
use Mojo::Base 'XCL::V', -signatures;

sub is_ok ($self) { exists $self->data->{val} }

sub val ($self) { $self->data->{val} }

sub err ($self) { $self->data->{err} }

sub can_set ($self) { exists $self->data->{set} }

sub set ($self, $value) {
  $self->data->{set}->($value);
}

sub display ($self, $depth) {
  if ($self->is_ok) {
    return 'Val('.$self->val->display($depth).')';
  }
  return 'Err('.$self->err->display($depth).')';
}

1;
