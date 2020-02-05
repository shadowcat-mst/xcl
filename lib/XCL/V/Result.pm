package XCL::V::Result;

use XCL::Class 'XCL::V';

sub is_ok ($self) { exists $self->data->{val} }

sub val ($self) { $self->data->{val} }

sub err ($self) { $self->data->{err} }

sub can_set_value ($self) { $self->data->{set} }

sub set_value ($self, $value) { $self->can_set_value->($value) }

sub display_data ($self, $depth) {
  if ($self->is_ok) {
    return '? '.$self->val->display($depth);
  }
  return 'err '.$self->err->display($depth);
}

sub f_get ($self) { ResultF $self }

1;
