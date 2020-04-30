package XCL::V::Float;

use Role::Tiny::With;
use XCL::Class 'XCL::V';

with 'XCL::V::Role::Numeric';

sub bool ($self) { ValF(Bool($self->data == 0 ? 0 : 1)) }

sub display_data ($self, $) {
  my $str = ''.$self->data;
  return $str =~ /^-?[0-9]+$/ ? "${str}.0" : $str;
}

sub _iota ($self) { return 1e-6 } # enhance this later

sub _is_zero ($self, $num) {
  my $iota = $self->_iota;
  return 0+!!($num >= -$iota and $num <= $iota);
}

sub _is_positive ($self, $num) {
  return 0+!!($num > $self->_iota);
}

sub f_to_int ($self, $) {
  my $int = int(my $float = $self->data);
  return ErrF [ NOT_AN_INTEGER => $self ]
    unless $self->_is_zero($float - $int);
  return ValF Int $int;
}

sub f_round_down_to_int ($self, $) {
  return ValF Int int($self->data);
}

sub f_round_up_to_int ($self, $) {
  my $float = $self->data;
  my $int = int $float;
  if ($self->_is_positive($float - $int)) {
    $int++;
  }
  return ValF Int int($self->data);
}

sub f_round_to_int ($self, $) {
  my $float = $self->data;
  my $int = int $float;
  if ($self->_isnt_negative($float+0.5 - $int)) {
    $int++;
  }
  return ValF Int int($self->data);
}

1;
