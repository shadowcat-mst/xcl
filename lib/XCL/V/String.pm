package XCL::V::String;

use XCL::Class 'XCL::V';

sub bool ($self) { ValF(Bool(length($self->data) ? 1 : 0)) }

# This is naive/wrong

sub display_data ($self, $) { q{'}.$self->data.q{'} }

sub string ($self) { ValF($self) }

async sub c_f_make ($class, $lst) {
  my @res;
  foreach my $v ($lst->values) {
    my $res = await $v->string;
    return $res unless $res->is_ok;
    push @res, $res->val->data;
  }
  return Val String join '', @res;
}

foreach my $op (qw(eq ne gt lt ge le)) {
  my $txt = ' 
    sub f_THISOP ($self, $lst) {
      return $_ for $self->_same_types($lst);
      ValF Bool $self->data THISOP $lst->data->[0]->data;
    }
    1;
  ';
  $txt =~ s/THISOP/$op/g;
  eval $txt or die "Failure evaluationg f_${op}: $@";
}

sub f_concat ($self, $lst) {
  $self->c_f_make(List [ $self, $lst->values ]);
}

sub f_to_int ($self, $) {
  ErrF [ NON_NUMERIC => $self ] unless $self->data =~ /^[0-9]+$/;
  ValF Int $self->data;
}

sub to_perl ($self) { $self->data }

1;
