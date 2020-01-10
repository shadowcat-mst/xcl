package XCL::V;

use Future; # needs to be somewhere
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

sub _same_types ($self, $lst, $type = $self->type) {
  if (grep $_->type ne $type, $lst->values) {
    return ErrF([
      Name('TYPES_MUST_MATCH') => map String($_->type), ($self, $lst->values)
    ]);
  }
  return ();
}

sub DESTROY {
  my ($self) = @_;
  return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
  return unless my $drop = $self->metadata->{drop};
  $drop->invoke(Scope({}), $self);
  return;
}

1;
