package XCL::V::Role::Listish;

use curry;
use XCL::Class -role;

async sub get ($self, $idx) {
  die "NOT YET" if $idx < 0;
  my $ary = $self->data;
  Result({
   ($idx <= $#$ary
     ? (val => $ary->[$idx])
     : (err => List([ Name('NO_SUCH_VALUE') => Int($idx) ]))),
  });
}

async sub set ($self, $idx, $value) {
  die "NOT YET" if $idx < 0;
  my $ary = $self->data;
  return Err([ Name('NO_SUCH_INDEX') => Int($idx) ]) if $idx > @$ary;
  return Val($ary->[$idx] = $value);
}

sub pairs ($self) {
  my $ary = $self->data;
  return map List([Int($_), $ary->[$_]]), 0 .. $#$ary;
}

sub keys ($self) {
  my $ary = $self->data;
  return map Int($_), 0 .. $#$ary;
}

sub values ($self) {
  return @{$self->data};
}

sub head ($self) { $self->data->[0] }

sub tail ($self) {
  return () unless my (undef, @tail) = $self->values;
  List \@tail;
}

sub ht ($self) {
  return () unless my ($head, @tail) = $self->values;
  ($head, List \@tail);
}

sub f_concat ($self, $lst) {
  # Check for List even if we're Call
  return $_ for $self->_same_types($lst, 'List');
  ValF($self->of_data([ map $_->values, $self, $lst->values ]));
}

sub f_pairs ($self, $) { ValF List [ $self->pairs ] }

sub f_keys ($self, $) { ValF List [ $self->keys ] }

sub f_values ($self, $) { ValF List [ $self->values ] }

sub f_head ($self, $) {
  my $val = $self->data->[0];
  defined($val) ? ValF($val) : ErrF([ Name('NO_SUCH_VALUE') ]);
}

sub f_tail ($self, $) {
  my ($first, @rest) = $self->values;
  defined($first) ? ValF(List \@rest) : ErrF([ Name('NO_SUCH_VALUE') ]);
}

sub f_ht ($self, $lst) {
  ValF List[ $self->f_head($lst), $self->f_tail($lst) ];
}

1;
