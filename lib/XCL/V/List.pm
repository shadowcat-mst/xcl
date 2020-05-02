package XCL::V::List;

use curry;
use Role::Tiny::With;
use XCL::Class 'XCL::V';

with 'XCL::V::Role::Indexable';
with 'XCL::V::Role::Listish';

sub index_is { 'Int' }

async sub evaluate_against ($self, $scope) {
  my @ret;
  foreach my $el (@{$self->data}) {
    state %class_is_basic;
    my $is_basic = $class_is_basic{ref($el)} //= 0+!!(
      ref($el)->can('evaluate_against')
        eq XCL::V->can('evaluate_against')
    );
    if ($is_basic) { push @ret, $el; next; }
    if ($el->is('Compound')
      and $el->data->[0]->is('Name')
      and $el->data->[0]->data eq '@'
    ) {
      my (undef, @tail) = @{$el->data};
      die "WHAT" unless @tail;
      return $_ for not_ok my $res = await $scope->eval(Compound \@tail);
      die "WHAT" unless $res->val->is('List');
      push @ret, $res->val->values;
      next;
    }
    return $_ for not_ok my $res = await $scope->eval($el);
    push @ret, $res->val;
  }
  return Val List(\@ret);
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

sub count ($self) { scalar @{$self->data} }

sub f_count ($self, $) {
  ValF Int scalar @{$self->data};
}

async sub _map_cb ($self, $scope, $lst, $wrap) {
  my ($head, $tail) = $lst->ht;
  return $_ for not_ok my $lres = await $scope->eval($head);
  my $arg = $lres->val;
  # require a callable for the moment
  #my $cb = $arg->can_invoke
  #  ? sub ($el) { $arg->invoke($scope, List[$tail->values, $el]) }
  #  : sub { ValF($arg) };
  my $cb = sub ($el) { $arg->invoke($scope, List[$tail->values, $el]) };
  my @val;
  foreach my $el ($self->values) {
    return $_ for not_ok my $wres = await $wrap->($el, await $cb->($el));
    push @val, $wres->val->values;
  }
  return Val List \@val;
}

sub fx_map ($self, $scope, $lst) {
  $self->_map_cb($scope, $lst, async sub ($, $res) {
    return $res unless $res->is_ok;
    return Val List[$res->val];
  });
}

sub fx_where ($self, $scope, $lst) {
  $self->_map_cb($scope, $lst, async sub ($el, $res) {
    return $_ for not_ok_except NO_SUCH_VALUE => $res;
    my $val = $res->is_ok ? $res->val : return Val List[];
    return $_ for not_ok my $bres = await $val->bool;
    return Val List[ $bres->val->data ? ($el) : () ];
  });
}

sub fx_pipe ($self, $scope, $lst) {
  $self->_map_cb($scope, $lst, async sub ($, $res) {
    return $_ for not_ok $res;
    my $val = $res->is_ok ? $res->val : return Val List[];
    Val($val->is('List') ? $val : List[$val]);
  });
}

async sub fx_each ($self, $scope, $lst) {
  my $empty = Val(List[]);
  return $_ for not_ok +await $self->_map_cb(
    $scope, $lst, async sub ($, $res) {
      return $res unless $res->is_ok;
      return $empty;
    }
  );
  return Val True;
}

async sub f_join ($self, $lst) {
  my ($join) = $lst->values;
  return Err [ Name('NOT_A_STRING'), $join ] unless $join->is('String');
  my @to_join;
  foreach my $el ($self->values) {
    return $_ for not_ok my $res = await $el->string;
    push @to_join, $res->val->data;
  }
  Val String join $join->data, @to_join;
}

sub fx_dict ($self, $scope, $) {
  Dict->c_f_make($scope, $self)
}

sub to_perl ($self) {
  [ map $_->to_perl, @{$self->data} ]
}

async sub fx_assign ($self, $scope, $lst) {
  # need to add @ support
  my ($vlist) = $lst->values;
  return Err [ Name('MISMATCH') ] unless $self->count == $vlist->count;
  foreach my $idx (0..$#{$self->data}) {
    return $_ for not_ok my $vres = await $vlist->get($idx);
    return $_ for not_ok +await dot_call_escape(
      $scope, $self->data->[$idx], assign => $vres->val
    );
  }
  return Val $self;
}

1;
