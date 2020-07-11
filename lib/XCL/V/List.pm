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
      return $_ for not_ok my $res = await concat $scope->eval(Compound \@tail);
      unless ($res->val->is('List')) {
        return $_ for not_ok $res = await concat dot_call_escape(
          $scope, $res->val, 'to_list'
        );
      }
      push @ret, $res->val->values;
      next;
    }
    return $_ for not_ok my $res = await concat $scope->eval($el);
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
  my $call = Call [$lst->values];
  my @val;
  my $yield = async sub ($el) {
    return $_ for not_ok my $res = await
      $wrap->($el, await concat $call->invoke($scope, List[$el]));
    push @val, $res->val->values;
    Val True;
  };
  return $_ for not_ok +await concat $self->_gen_cb($yield);
  return Val List \@val;
}

async sub _gen_cb ($self, $yield) {
  foreach my $el ($self->values) {
    return $_ for not_ok +await concat $yield->($el);
  }
  return Val True;
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
    return $_ for not_ok my $bres = await concat $val->bool;
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
  my $call = Call [ $lst->values ];
  foreach my $el ($self->values) {
    return $_ for not_ok +await concat $call->invoke($scope, List[$el]);
  }
  return Val True;
}

async sub f_join ($self, $lst) {
  my ($join) = $lst->values;
  return Err [ Name('NOT_A_STRING'), $join ] unless $join->is('String');
  my @to_join;
  foreach my $el ($self->values) {
    return $_ for not_ok my $res = await concat $el->string;
    push @to_join, $res->val->data;
  }
  Val String join $join->data, @to_join;
}

sub fx_to_dict ($self, $scope, $) {
  Dict->c_f_make($scope, $self)
}

sub to_perl ($self) {
  [ map $_->to_perl, @{$self->data} ]
}

async sub fx_assign ($self, $scope, $lst) {
  return Err [ Name('MISMATCH') ] unless my $from = $lst->head;
  return Err [ Name('MISMATCH') ] unless $from->is('List');
  my @assign_from = $from->values;
  my @assign_to = $self->values;
  my @dict_to;
  while (
    @assign_to
    and ($assign_to[0]->is('Compound') or $assign_to[0]->is('Call'))
    and grep $_->is('Name') && $_->data =~ /^[:%]$/, $assign_to[0]->data->[0]
  ) {
    push @dict_to, shift @assign_to;
  }
  if (@dict_to) {
    my @dict_from;
    while (
      @assign_from
      and grep $_->{is_pair} || $_->{is_pair_proto},
            $assign_from[0]->metadata
    ) {
      push @dict_from, shift @assign_from;
    }
    return $_ for not_ok
      my $dres = await concat Dict->c_fx_make($scope, List \@dict_from);
    return $_ for not_ok +await concat Dict->destructure(
      $scope, List[List(\@dict_to), $dres->val]
    );
  }
  while (my $to_slot = shift @assign_to) {
    my $name = $to_slot->is('Name') ? $to_slot->data : '';
    if ($name eq '@') {
      return Val $from;
    } elsif (
      ($to_slot->is('Call') or $to_slot->is('Compound'))
      and grep $_->is('Name') && $_->data eq '@',
        (my $splat_call = $to_slot->to_call)->data->[0]
    ) {
      die "WHAT" unless (my (undef, $splat_to) = @{$splat_call->data}) == 2;
      return $_ for not_ok +await concat dot_call_escape(
        $scope, $splat_to, assign => List \@assign_from
      );
      return Val $from;
    }
    return $_ for not_ok +await concat dot_call_escape(
      $scope, $to_slot, assign => (shift @assign_from // ())
    );
  }
  return Err [ Name('MISMATCH') ] if @assign_from;
  return Val $from;
}

1;
