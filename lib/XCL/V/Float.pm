package XCL::V::Float;

use Role::Tiny::With;
use XCL::Class 'XCL::V';

with 'XCL::V::Role::Numeric';

sub bool ($self) { ValF(Bool($self->data == 0 ? 0 : 1)) }

sub display_data ($self, $) {
  my $str = ''.$self->data;
  return $str =~ /^-?[0-9]+$/ ? "${str}.0" : $str;
}

sub _is_zero ($self, $num) {
  return 0+!!($num >= -1e-6 and $num <= 1e-6);
}

sub _is_positive ($self, $num) {
  return 0+!!($num > 1e-6);
}

sub f_to_int ($self, $) {
  my $int = int(my $float = $self->data);
  return ErrF [ NOT_AN_INTEGER => $self ]
    unless $self->_is_zero($float - $int);
  return Int $int;
}

1;
