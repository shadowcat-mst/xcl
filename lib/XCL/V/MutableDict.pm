package XCL::V::MutableDict;

use XCL::Class 'XCL::V::Dict';

with 'XCL::V::Role::MutableIndexable';

sub set ($self, $index, $value) {
  return ValF($self->data->{$index->data} = $value);
}

1;
