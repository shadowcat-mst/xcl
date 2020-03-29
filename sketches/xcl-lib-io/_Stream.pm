package XCL::Lib::IO::_Stream;

use Mojo::Base 'Mojo::IOLoop::Stream', -signatures;
use Mojo::Promise;

sub _assert_no_subscribers ($self, $type) {
  die "Can't start sync ${type} with active listeners"
    if $self->has_subscribers($type);
}

sub read_until_p ($self, $end) {
  $self->_assert_no_subscribers('read');
  my $re = qr{^(.*?)\Q$end}m;
  if ($self->{buffer} =~ s/$re//) {
    return Mojo::Promise->resolve($1);
  }
  Mojo::Promise->new->tap(sub ($p) {
    $self->on(read => sub ($, $data) {
      if (($self->{buffer} .= $data) =~ s/$re//) {
        $self->unsubscribe('read');
        $p->resolve($1);
      }
    });
    $self->{in_sync_read} = 1;
  });
}

sub read_p ($self, $bytes = 1024**2) {
  $self->_assert_no_subscribers('read');
  if (my ($buf) = grep defined && (my $length = length), delete $self->{buffer}) {
    $self->{buffer} = substr($buf, $bytes, $length - $bytes, '')
      if $length > $bytes;
    return Mojo::Promise->resolve($buf);
  }
  Mojo::Promise->new->tap(sub ($p) {
    $self->once(read => sub ($, $data, $length = length($data)) {
      $self->{buffer} = substr($data, $bytes, $length - $bytes, '')
        if $length > $bytes;
      $p->resolve($data);
    });
    $self->{in_sync_read} = 1;
  })
}

sub on ($self, $name, @on) {
  if ($name eq 'read') {
    die "Can't register 'read' listener while in sync read mode"
      if $self->{in_sync_read};
    
    unless ($self->has_subscribers('read')) {
      Mojo::IOLoop->next_tick(sub {
        if (my ($buf) = grep defined && length, delete $self->{buffer}) {
          $self->start->emit(read => $buf);
        }
      });
    }
  }
  $self->next::method($name, @on);
}

sub unsubscribe ($self, $name, @unsub) {
  return $self unless $self->has_subscribers($name);
  $self->next::method($name, @unsub);
  delete $self->stop->{in_sync_read}
    if $name eq 'read' and not $self->has_subscribers('read');
  return $self;
}

sub write_p ($self, $data) {
  Mojo::Promise->new->tap(sub ($p) {
    $self->write($data, $p->curry::resolve);
  });
}

1;
