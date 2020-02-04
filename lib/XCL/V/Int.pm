package XCL::V::Int;

use Role::Tiny::With;
use XCL::Class 'XCL::V';

with 'XCL::V::Role::Numeric';

sub bool ($self) { ValF(Bool($self->data == 0 ? 1 : 0)) }

sub display_data ($self, $) { ''.$self->data }

sub c_f_range ($self, $lst) {
  return $_ for $self->_same_types($lst);
  my ($start, $end) = map $_->data, $lst->values;
  my @range = (
    ($start > $end)
      ? (reverse $end..$start)
      : ($start..$end)
  );
  ValF List [ map Int($_), @range ];
}

1;
