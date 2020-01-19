package XCL::V::Result;

use XCL::Class 'XCL::V';

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

sub f_get ($self) { ResultF $self }

1;
