package XCL::V::MutableList;

use XCL::Class 'XCL::V::List';

with 'XCL::V::Role::MutableIndexable';

async sub set ($self, $index, $value) {
  my $idx = $index->data;
  die "NOT YET" if $idx < 0;
  my $ary = $self->data;
  return Err([ Name('NO_SUCH_INDEX') => Int($idx) ]) if $idx > @$ary;
  return Val($ary->[$idx] = $value);
}

1;
