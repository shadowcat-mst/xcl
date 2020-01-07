package XCL::V::Int;

use Mojo::Base 'XCL::V', -signatures;

sub bool ($self) { Val(Bool($self->data == 0 ? 1 : 0)) }

sub display ($self, @) { ''.$self->data }

1;
