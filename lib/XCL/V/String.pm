package XCL::V::String;

use Mojo::Base 'XCL::V', -signatures;

sub bool ($self) { Val(Bool(length($self->data) ? 1 : 0)) }

# This is naive/wrong

sub display ($self, @) { q{'}.$self->data.q{'} }

sub c_f_make ($class, $lst) {
  return Val String join '', map {
    my $res = $_->string;
    return $res unless $res->is_ok;
    $res->val->data;
  } $lst->values;
}

1;
