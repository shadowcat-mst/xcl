package XCL::Value;

use XCL::Class;

ro 'type';
ro 'data';

sub new_value ($self, $data) {
  ref($self)->new(type => $self->type, data => $data);
}

1;
