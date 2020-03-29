package XCL::Lib::IO::Role::WriteHandle;

use XCL::Class -role;

sub _maybe_encode ($self, $data) {
  $data->is('Bytes') ? $data->data : $self->_definitely_encode($data)
}

sub _definitely_encode ($self, $data) {
  encode('UTF-8', $data->data);
}

sub _encoded ($self, @data) {
  join '', map $self->_maybe_encode($_), @data;
}
 
async sub f_write ($self, @data) {
  Val await $self->data->write_p($self->_encoded(@data));
}

async sub f_writeline ($self, @data) {
  Val await $self->data->write_p(@data, $self->_newline);
}

sub f_queue_write ($self, @data) {
  $self->data->write($self->_encoded(@data));
  return ValF True;
}

sub f_queue_writeline ($self, @data) {
  $self->f_queue_write(@data, $self->_newline);
}

async sub f_drain ($self) {
  await $self->data->drain_p;
  return Val True;
}

1;
