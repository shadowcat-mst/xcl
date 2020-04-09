package XCL::V::List;

use curry;
use Role::Tiny::With;
use XCL::Class 'XCL::V';

with 'XCL::V::Role::Listish';

async sub evaluate_against ($self, $scope) {
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

sub display_data ($self, $depth) {
  return $self->SUPER::display_data(0) unless $depth;
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

sub _arg_to_cb ($self, $scope, $arg) {
  if ($arg->is('Fexpr') or $arg->is('Call') or $arg->is('Native')) {
    return sub ($el) { $arg->invoke($scope, List[$el]) };
  }
  if ($arg->is('Block')) {
    my $f = Fexpr({
      argnames => [ 'this', '$.' ],
      scope => $scope,
      body => $arg,
    });
    return sub ($el) {
      $f->invoke($scope, List[ $el, Call [ $el, Name('.') ] ]);
    };
  }
  return sub { ValF($arg) };
}

async sub _map_cb ($self, $scope, $lst, $wrap) {
  return $_ for not_ok my $lres = await $scope->eval($lst);
  my $cb = $self->_arg_to_cb($scope, $lres->val->values);
  my @val;
  foreach my $el ($self->values) {
    return $_ for not_ok my $res = await $cb->($el);
    return $_ for not_ok my $wres = await $wrap->($res->val);
    push @val, $wres->val->values;
  }
  return Val List \@val;
}

sub fx_map ($self, $scope, $lst) {
  $self->_map_cb($scope, $lst, sub ($val) { ValF List[$val] });
}

sub fx_where ($self, $scope, $lst) {
  $self->_map_cb($scope, $lst, async sub ($val) {
    return $_ for not_ok my $bres = await $val->bool;
    return Val List[ $bres->val->data ? ($val) : () ];
  });
}

sub fx_pipe ($self, $scope, $lst) {
  $self->_map_cb($scope, $lst, async sub ($val) {
    Val($val->is('List') ? $val : List[$val]);
  });
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
