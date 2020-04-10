package XCL::V::Bytes;

use XCL::Class 'XCL::V';

sub to_perl { shift->data }

sub bool ($self) { ValF(Bool(length($self->data) ? 1 : 0)) }

1;
