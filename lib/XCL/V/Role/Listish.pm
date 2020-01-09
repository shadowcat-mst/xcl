package XCL::V::Role::Listish;

use curry;
use XCL::Values;
use Mojo::Base -role, -signatures, -async;

sub get ($self, $idx) {
  die "NOT YET" if $idx < 0;
  my $ary = $self->data;
  Result({
   ($idx <= $#$ary
     ? (val => $ary->[$idx])
     : (err => List([ Name('NO_SUCH_VALUE') => Int($idx) ]))),
   (set => $self->curry::weak::set($idx)),
  });
}

sub set ($self, $idx, $value) {
  die "NOT YET" if $idx < 0;
  my $ary = $self->data;
  return Err([ Name('NO_SUCH_INDEX') => Int($idx) ]) if $idx > @$ary;
  return Val($ary->[$idx] = $value);
}

sub keys ($self) {
  my $ary = $self->data;
  return map Int($_), 0 .. $ary;
}

sub values ($self) {
  return @{$self->data};
}

sub f_concat ($self, $lst) {
  # Check for List even if we're Call
  return $_ for $self->_same_types($lst, 'List');
  ValF($self->new(data => [ map $_->values, $self, $lst->values ]));
}

1;
