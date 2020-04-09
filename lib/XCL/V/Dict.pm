package XCL::V::Dict;

use curry;
use XCL::Class 'XCL::V';

async sub get ($self, $key) {
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
  return ValF($self->data->{$key} = $value);
}

sub _invoke ($self, $, $vals) {
  return ErrF([ Name('WRONG_ARG_COUNT') => Int(scalar $vals->values) ])
    unless (my ($string) = $vals->values) == 1;
  return ErrF([ Name('NOT_A_STRING') => String($string->type) ])
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

sub display_data ($self, $depth) {
  return $self->SUPER::display_data(0) unless $depth;
  my $in_depth = $depth - 1;
  my @res;
  my $indent = '  ' x (my $e = $Eval_Depth + 1);
  dynamically $Eval_Depth = $e;
  foreach my $key (sort CORE::keys %{$self->data}) {
    my $value = $self->data->{$key};
    my $display_value = defined($value)
      ? $self->data->{$key}->display($in_depth)
      : 'MISSING';
    push @res, map s/^/${indent}/mgr, do {
      if ($key =~ /^[a-zA-Z_]\w*$/) {
        ":${key} ${display_value}";
      } else {
        '('.String($key)->display($in_depth).', '.$display_value.')';
      }
    };
  }
  return "%(\n".join(",\n", @res)."\n)";
}

sub bool ($self) { ValF(Bool(CORE::keys(%{$self->data}) ? 1 : 0)) }

sub c_f_make ($class, $, $lst) {
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
