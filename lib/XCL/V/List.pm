package XCL::V::List;

use curry;
use XCL::Values;
use Mojo::Base 'XCL::V', -signatures;

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

sub get ($self, $idx) {
  die "NOT YET" if $idx < 0;
  my $ary = $self->data;
  Result({
   ($idx <= $#$ary
     ? (val => $ary->[$idx])
     : (err => List([ Name('NO_SUCH_VALUE') => Int($idx) ]))),
   (set => $self->curry::weak::set($idx)),
  });
}

sub set ($self, $idx, $value) {
  die "NOT YET" if $idx < 0;
  my $ary = $self->data;
  return Err([ Name('NO_SUCH_INDEX') => Int($idx) ]) if $idx > @$ary;
  return Val($ary->[$idx] = $value);
}

sub invoke ($self, $, $vals) {
  return Err([ Name('WRONG_ARG_COUNT') => Int(scalar $vals->values) ])
    unless (my ($idx) = $vals->values) == 1;
  return Err([ Name('NOT_AN_INT') => String($idx->type) ])
    unless $idx->is('Int');
  $self->get($idx->data);
}

sub keys ($self) {
  my $ary = $self->data;
  return map Int($_), 0 .. $ary;
}

sub values ($self) {
  return @{$self->data};
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

1;
