package XCL::V::Result;

use XCL::Class 'XCL::V';

sub is_ok ($self) { 0+!!exists $self->data->{val} }

sub val ($self) { $self->data->{val} }

sub err ($self) { $self->data->{err} }

sub display_data ($self, $depth) {
  if ($self->is_ok) {
    return '? '.$self->val->display($depth);
  }
  return 'err '.$self->err->display($depth);
}

sub get ($self) {
  return $self->val if $self->is_ok;
  die $self->err->display(8)."\n";
}

async sub bool ($self) {
  return $self unless $self->is_ok;
  return await $self->val->bool;
}

sub f_get ($self, $) { ResultF $self }

sub f_is_ok ($self, $) { ValF Bool $self->is_ok }

sub f_val ($self, $) {
  return ErrF([ Name 'NO_SUCH_VALUE' ]) unless $self->is_ok;
  return ValF $self->val;
}

sub f_err ($self, $) {
  return ErrF([ Name 'NO_SUCH_VALUE' ]) if $self->is_ok;
  return ValF $self->err;
}

1;
