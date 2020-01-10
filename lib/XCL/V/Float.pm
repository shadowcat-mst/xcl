package XCL::V::Float;

use Role::Tiny::With;
use Mojo::Base 'XCL::V', -signatures;

with 'XCL::V::Role::Numeric';

sub bool ($self) { ValF(Bool($self->data == 0 ? 1 : 0)) }

sub display ($self, @) {
  my $str = ''.$self->data;
  return $str =~ /^-?[0-9]+$/ ? "${str}.0" : $str;
}

1;
