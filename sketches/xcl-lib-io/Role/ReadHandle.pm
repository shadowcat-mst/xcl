package XCL::Lib::IO::Role::ReadHandle;

use XCL::Class -role;

async sub f_readline ($self, $) {
  Val String decode('UTF-8', await $self->data->read_until($self->_newline));
}

async sub f_read_until ($self, $lst) {
  Val Bytes await $self->data->read_until(($lst->values)[0]->data);
}

async sub f_read ($self, $lst) {
  my @v = $lst->values;
  Val await $self->data->read(@v ? $v[0]->data : ());
}

sub f_on_read ($self, $lst) {
  ValF List [
    map Native({
      code => $self->data->curry::weak::unsubscribe(read => $_)
    }),
      map $self->data->on(read => $_),
        $lst->values
  ];
}

1;
