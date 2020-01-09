package XCL::V::Int;

use Role::Tiny::With;
use Mojo::Base 'XCL::V', -signatures;

with 'XCL::V::Role::Numeric';

sub bool ($self) { Val(Bool($self->data == 0 ? 1 : 0)) }

sub display ($self, @) { ''.$self->data }

1;
