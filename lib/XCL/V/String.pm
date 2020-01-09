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

foreach my $op (qw(eq ne gt lt ge le)) {
  my $txt = ' 
    sub f_THISOP ($self, $lst) {
      return $_ for $self->_same_types($lst);
      Val Bool $self->data THISOP $lst->data->[0]->data;
    }
    1;
  ';
  $txt =~ s/THISOP/$op/g;
  eval $txt or die "Failure evaluationg f_${op}: $@";
}

1;
