package XCL::V::Scope;

use XCL::Values;
use Mojo::Base 'XCL::V', -signatres;

sub get ($self, $key) {
  my $res = $self->data->get($key);
  return $res unless $res->is_ok;
  my $val = $res->val;
  return $val if $val->is('Result');
  return $val->invoke($self, List);
}

sub set ($self, $key, $value) {
  Val($self->data->data->{$key} = $value);
}

sub invoke ($self, $, $vals) {
  return Err([ Name('WRONG_ARG_COUNT') => Int(scalar $vals->values) ])
    unless (my ($string) = $vals->values) == 1;
  return Err([ Name('NOT_A_STRING') => String($string->type) ])
    unless $string->is('String');
  return $self->get($string->data);
}

sub derive ($self, $merge) {
  Scope(Dict({ %{$self->data->data}, %$merge }));
}

sub snapshot ($self) {
  Scope(Dict({ %{$self->data->data} }));
}

sub display ($self, $depth) {
  'Scope('.$self->data->display($depth).')'
}

1;
