package XCL::V;

use XCL::Values;
use Mojo::Base -base, -signatures;

has [ qw(data metadata) ];

sub evaluate_against ($self, $) { Val($self) }

sub invoke ($self, $, $) {
  Err([ Name('CANT_INVOKE') => String($self->display) ])
}

sub is ($self, $type) {
  $self->isa("XCL::V::${type}");
}

sub type ($self) {
  (split '::', ref($self))[-1];
}

sub display ($self, @) { $self->type.'()' }

sub bool ($self) { Err([ Name('CANT_BOOLEAN') => String($self->type) ]) }

sub string ($self) { Err([ Name('CANT_STRINGIFY') => String($self->type) ]) }

1;
