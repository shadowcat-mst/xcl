package XCL::V::Int;

use XCL::Class 'XCL::V';

with 'XCL::V::Role::Numeric';

sub bool ($self) { ValF(Bool($self->data == 0 ? 0 : 1)) }

sub display_data ($self, $) { ''.$self->data }

sub c_f_range ($class, $lst) {
  return $_ for $class->_same_types($lst);
  my ($start, $end) = map $_->data, $lst->values;
  my @range = (
    ($start > $end)
      ? (reverse $end..$start)
      : ($start..$end)
  );
  ValF List [ map Int($_), @range ];
}

sub f_to_int ($self, $) { ValF Int $self->data }

sub _is_zero ($self, $num) { 0+!!($num == 0) }
sub _is_positive ($self, $num) { 0+!!($num > 0) }

1;
