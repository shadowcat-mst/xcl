package XCL::V::Float;

use Mojo::Base 'XCL::V', -signatures;

sub bool ($self) { Val(Bool($self->data == 0 ? 1 : 0)) }

sub display ($self, @) {
  my $str = ''.$self->data;
  return $str =~ /^-?[0-9]+$/ ? "${str}.0" : $str;
}

1;
