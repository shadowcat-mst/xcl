package XCL::V::List;

use curry;
use XCL::Values;
use Mojo::Base 'XCL::V', -signatures, -async;

async sub evaluate_against {
  my ($self, $scope) = @_;
  my @ret;
  foreach my $el (@{$self->data}) {
    my $res = await $el->evaluate_against($scope);
    return $res unless $res->is_ok;
    push @ret, $res->val;
  }
  return List(\@ret);
}

sub invoke ($self, $, $vals) {
  return Err([ Name('WRONG_ARG_COUNT') => Int(scalar $vals->values) ])
    unless (my ($idx) = $vals->values) == 1;
  return Err([ Name('NOT_AN_INT') => String($idx->type) ])
    unless $idx->is('Int');
  $self->get($idx->data);
}

sub display ($self, $depth) {
  return $self->SUPER::display(0) unless $depth;
  my $in_depth = $depth - 1;
  my @res;
  foreach my $val ($self->values) {
    push @res, $val->display($in_depth);
  }
  return '('.join(', ', @res).')';
}

sub bool ($self) { Val(Bool(@{$self->data} ? 1 : 0)) }

sub f_count ($self, $) {
  ValF Int scalar @{$self->data};
}

async sub f_map {
  my ($self, $lst) = @_;
  my ($f) = $lst->values;
  my @val;
  foreach my $el ($self->values) {
    my $res = await Call([ $f, $el ])->evaluate_against(Scope({}));
    return $res unless $res->is_ok;
    push @val, $res->val;
  }
  return Val List \@val;
}

1;
