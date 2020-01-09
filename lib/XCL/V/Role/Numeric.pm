package XCL::V::Role::Numeric;

use XCL::Values;
use Mojo::Base -role, -signatures;

my $MAX_SAFE_INT = 2**53;

sub _same_types ($self, $lst) {
  if (grep $_->type ne $type, $lst->values) {
    return Err([
      Name('TYPES_MUST_MATCH') => map String($_->type), ($self, $lst->values)
    ]);
  }
  return ();
}

sub f_plus ($self, $lst) {
  return $_ for $self->_same_types($lst);
  my $acc = $self->data;
  foreach my $val (map $_->data, $lst->values) {
    if ($type eq 'Int' and $MAX_SAFE_INT - $acc < $val) {
      return Err([ Name('INT_OVERFLOW') ]);
    }
    $acc += $val;
  }
  Val($self->new(data => $acc));
}

sub f_multiply ($self, $lst) {
  return $_ for $self->_same_types($lst);
  my $acc = $self->data;
  foreach my $val (map $_->data, @rest) {
    if ($type =~ /Int$/ and $MAX_SAFE_INT / $acc > $val) {
      return Err([ Name('INT_OVERFLOW') ]);
    }
    $acc *= $val;
  }
  Val($self->new(data => $acc));
}

sub f_minus ($self, $lst) {
  return $_ for $self->_same_types($lst);
  Val($self->new(data => $self->data - $lst->data->[0]->data));
}

sub f_divide ($self, $lst) {
  return $_ for $self->_same_types($lst);
  Val(Float(data => $self->data / $lst->data->[0]->data));
}

sub f_to_int ($self, $) { return Int($self->data) }
sub f_to_float ($self, $) { return Float($self->data) }

1;
