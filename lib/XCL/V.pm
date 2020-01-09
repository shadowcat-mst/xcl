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

# maybe doesn't belong here but in a role but shrug

sub _same_types ($self, $lst) {
  my $type = $self->type;
  if (grep $_->type ne $type, $lst->values) {
    return Err([
      Name('TYPES_MUST_MATCH') => map String($_->type), ($self, $lst->values)
    ]);
  }
  return ();
}

1;
