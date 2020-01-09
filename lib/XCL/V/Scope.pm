package XCL::V::Scope;

use XCL::Values;
use Mojo::Base 'XCL::V', -signatres;

sub get ($self, $key) {
  my $res = $self->data->get($key);
  return $res unless $res->is_ok;
  my $val = $res->val;
  return $val if $val->is('Result');
  return $val->invoke($self, List []);
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

sub c_fx_val ($class, $self, $lst) { $self->intro(\&Val, $lst); }
sub c_fx_var ($class, $self, $lst) { $self->intro(\&Var, $lst); }

sub fx_val ($self, $, $lst) { $self->intro(\&Val, $lst); }
sub fx_var ($self, $, $lst) { $self->intro(\&Var, $lst); }

sub intro ($self, $type, $lst) {
  my ($name) = @{$lst->data};
  return Err([ Name('NOT_A_NAME') => String($name->type) ])
    unless $name->is('Name');
  my $_set = $env->curry::weak::set($name->data);
  return ResultF({
    err => List([ Name('INTRO_REQUIRES_SET') => String($name->data) ]),
    set => sub { $_set->($type->($_[0])) },
  });
}

sub c_fx_current ($class, $scope, $lst) { ValF($scope) }

1;
