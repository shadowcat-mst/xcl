package XCL::V::Dict;

use curry;
use XCL::Values;
use Mojo::Base 'XCL::V', -signatures;

sub get ($self, $key) {
  my $dict = $self->data;
  Result({
    ($dict->{$key}
      ? (val => $dict->{$key})
      : (err => List([ Name('NO_SUCH_VALUE') => String($key) ]))
    ),
    set => $self->curry::weak::set($key),
  });
}

sub set ($self, $key, $value) {
  return Val($self->data->{$key} = $value);
}

sub invoke ($self, $, $vals) {
  return Err([ Name('WRONG_ARG_COUNT') => Int(scalar $vals->values) ])
    unless (my ($string) = $vals->values) == 1;
  return Err([ Name('NOT_A_STRING') => String($string->type) ])
    unless $string->is('String');
  $self->get($string->data);
}

sub has_key ($self, $key) {
  $self->data->{$key} ? 1 : 0;
}

sub keys ($self) {
  map String($_), sort CORE::keys %{$self->data};
}

sub values ($self) {
  @{$self->data}{sort CORE::keys %{$self->data}};
}

sub pairs ($self) {
  my $d = $self->data;
  return map List([ String($_), $d->{$_} ]), sort CORE::keys %$d;
}

sub display ($self, $depth) {
  return $self->SUPER::display(0) unless $depth;
  my $in_depth = $depth - 1;
  my @res;
  foreach my $key ($self->keys) {
    push @res, '('
      .$key->display($in_depth)
      .', '
      .$self->data->{$key->data}->display($in_depth)
      .')';
  }
  return '%('.join(', ', @res).')';
}

sub bool ($self) { ValF(Bool(CORE::keys(%{$self->data}) ? 1 : 0)) }

sub c_f_make ($class, $lst) {
  my @pairs = $lst->values;
  return ErrF([ Name('NOT_PAIRS'), String('FIXME') ])
    if grep !($_->is('List') and @{$_->data} == 2), @pairs;
  return ValF(Dict({
    map +($_->data->[0]->data, $_->data->[1]),
      @pairs
  }));
}

sub f_pairs ($self, $) {
  ValF List [ $self->pairs ];
}

sub c_f_concat ($class, $lst) {
  return $_ for $class->_same_types($lst);
  ValF Dict +{ map %$_, $lst->values };
}

sub to_perl ($self) {
  my %d = %{$self->data};
  +{ map +($_ => $d{$_}->to_perl), CORE::keys %d };
}

1;
