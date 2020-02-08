package XCL::V::Float;

use Role::Tiny::With;
use XCL::Class 'XCL::V';

with 'XCL::V::Role::Numeric';

sub bool ($self) { ValF(Bool($self->data == 0 ? 0 : 1)) }

sub display_data ($self, $) {
  my $str = ''.$self->data;
  return $str =~ /^-?[0-9]+$/ ? "${str}.0" : $str;
}

1;
