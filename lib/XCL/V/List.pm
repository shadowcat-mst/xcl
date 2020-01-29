package XCL::V::List;

use curry;
use Role::Tiny::With;
use XCL::Class 'XCL::V';

with 'XCL::V::Role::Listish';

async sub evaluate_against {
  my ($self, $scope) = @_;
  my @ret;
  foreach my $el (@{$self->data}) {
    state %class_is_basic;
    my $is_basic = $class_is_basic{ref($el)} //= 0+!!(
      ref($el)->can('evaluate_against')
        eq XCL::V->can('evaluate_against')
    );
    if ($is_basic) { push @ret, $el; next; }
    return $_ for not_ok my $res = await $scope->eval($el);
    push @ret, $res->val;
  }
  return Val List(\@ret);
}

sub _invoke ($self, $, $vals) {
  return ErrF([ Name('WRONG_ARG_COUNT') => Int(scalar $vals->values) ])
    unless (my ($idx) = $vals->values) == 1;
  return ErrF([ Name('NOT_AN_INT') => String($idx->type) ])
    unless $idx->is('Int');
  ResultF $self->get($idx->data);
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

sub bool ($self) { ValF(Bool(@{$self->data} ? 1 : 0)) }

sub f_count ($self, $) {
  ValF Int scalar @{$self->data};
}

async sub f_map {
  my ($self, $lst) = @_;
  my ($f) = $lst->values;
  my @val;
  foreach my $el ($self->values) {
    my $res = await Scope({})->eval(Call([ $f, $el ]));
    return $res unless $res->is_ok;
    push @val, $res->val;
  }
  return Val List \@val;
}

sub to_perl ($self) {
  [ map $_->to_perl, @{$self->data} ]
}

sub head ($self) { $self->data->[0] }

sub tail ($self) {
  return () unless my (undef, @tail) = $self->values;
  List \@tail;
}

sub ht ($self) {
  return () unless my ($head, @tail) = $self->values;
  ($head, List \@tail);
}

1;
