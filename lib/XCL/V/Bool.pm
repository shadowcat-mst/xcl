package XCL::V::Bool;

use XCL::Values;
use Mojo::Base 'XCL::V', -signatures;

sub bool ($self) { Val($self) }

sub display ($self, @) {
  $self->data ? 'true' : 'false'
}

1;
