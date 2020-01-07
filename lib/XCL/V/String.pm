package XCL::V::String;

use Mojo::Base 'XCL::V', -signatures;

sub bool ($self) { Val(Bool(length($self->data) ? 1 : 0)) }

# This is naive/wrong

sub display ($self, @) { q{'}.$self->data.q{'} }

1;
