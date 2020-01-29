package XCL::V::Role::Numeric;

use XCL::Class -role;

my $MAX_SAFE_INT = 2**53;

sub f_plus ($self, $lst) {
  return $_ for $self->_same_types($lst);
  my $type = $self->type;
  my $acc = $self->data;
  foreach my $val (map $_->data, $lst->values) {
    if ($type eq 'Int' and $MAX_SAFE_INT - $acc < $val) {
      return ErrF([ Name('INT_OVERFLOW') ]);
    }
    $acc += $val;
  }
  ValF($self->of_data($acc));
}

sub f_multiply ($self, $lst) {
  return $_ for $self->_same_types($lst);
  my $type = $self->type;
  my $acc = $self->data;
  foreach my $val (map $_->data, $lst->values) {
    if ($type =~ /Int$/ and $MAX_SAFE_INT / $acc > $val) {
      return ErrF([ Name('INT_OVERFLOW') ]);
    }
    $acc *= $val;
  }
  ValF($self->of_data($acc));
}

sub f_minus ($self, $lst) {
  return $_ for $self->_same_types($lst);
  ValF($self->of_data($self->data - $lst->data->[0]->data));
}

sub f_divide ($self, $lst) {
  return $_ for $self->_same_types($lst);
  ValF(Float($self->data / $lst->data->[0]->data));
}

sub f_to_int ($self, $) { return ValF Int($self->data) }
sub f_to_float ($self, $) { return ValF Float($self->data) }

sub _is_zero ($self, $num) {
  # hack, move this to the classes
  if ($self->type eq 'Float') {
    return 0+!!($num >= -1e-6 and $num <= 1e-6);
  }
  return 0+!!($num == 0);
}

sub _is_positive ($self, $num) {
  # hack, move this to the classes
  if ($self->type eq 'Float') {
    return 0+!!($num > 1e-6);
  }
  return 0+!!($num > 0);
}

sub _isnt_negative ($self, $num) { 0+!!$self->_is_positive(-$num) }

sub f_eq ($self, $lst) {
  return $_ for $self->_same_types($lst);
  return ValF Bool $self->_is_zero($self->data - $lst->data->[0]->data);
}

sub f_ne ($self, $lst) {
  return $_ for $self->_same_types($lst);
  return ValF Bool 0+!!$self->_is_zero($self->data - $lst->data->[0]->data);
}

sub f_gt ($self, $lst) {
  return $_ for $self->_same_types($lst);
  return ValF Bool $self->_is_positive($self->data - $lst->data->[0]->data);
}

sub f_lt ($self, $lst) {
  return $_ for $self->_same_types($lst);
  return ValF Bool $self->_is_positive($lst->data->[0]->data - $self->data);
}

sub f_ge ($self, $lst) {
  return $_ for $self->_same_types($lst);
  return ValF Bool $self->_isnt_negative($self->data - $lst->data->[0]->data);
}

sub f_le ($self, $lst) {
  return $_ for $self->_same_types($lst);
  return ValF Bool $self->_isnt_negative($lst->data->[0]->data - $self->data);
}

sub to_perl ($self) { $self->data }

1;
