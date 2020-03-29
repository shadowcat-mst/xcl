package XCL::Lib::IO::Role::Newline;

use XCL::Class -role;

sub _newline ($self) {
  ($self->metadata->{nl} || Bytes("\n"))->data;
}

sub f_nl ($self, $lst) {
  if (my ($nl) = $lst->values) {
    die "Wut" unless $nl->is('Bytes');
    $self->metadata->{nl} = $nl;
    return ValF $self;
  }
  my $meta = $self->curry::weak::metadata;
  return Future->done(Result({
    val => $self->_newline,
    set => sub ($nl) {
      die "Wut" unless $nl->is('Bytes');
      $meta->()->{nl} = $nl;
    },
  }));
}

# This does not belong here, move it later

sub display_data ($self, $) { "Name('${self}')" }

1;
