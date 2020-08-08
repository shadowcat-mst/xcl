package XCL::V::List;

use curry;
use XCL::Class 'XCL::V';

with 'XCL::V::Role::MutableIndexable';
with 'XCL::V::Role::Listish';

sub index_is { 'Int' }

async sub _expand ($self, $scope, $scalar) {
  my @ret;
  foreach my $el (@{$self->data}) {
    if ($el->is('Compound')
      and $el->data->[0]->is('Name')
      and $el->data->[0]->data eq '@'
    ) {
      my (undef, @tail) = @{$el->data};
      die "WHAT" unless @tail;
      return $_ for not_ok my $res = await $scope->eval_concat(Compound \@tail);
      unless ($res->val->is('List')) {
        return $_ for not_ok $res = await $scope->invoke_method_of(
          $res->val, 'to_list', List[]
        );
      }
      push @ret, $res->val->values;
      next;
    }
    return $_ for not_ok my $res = await $scalar->($scope, $el);
    push @ret, $res->val;
  }
  return Val List(\@ret);
}

async sub evaluate_against ($self, $scope) {
  return await $self->_expand($scope, async sub ($scope, $el) {
    await $scope->eval_concat($el);
  });
}

async sub f_expand ($self, $scope, $) {
  return await $self->_expand($scope, async sub ($scope, $el) {
    Val $el;
  });
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

async sub f_stream ($self, $) {
  my @source = $self->values;
  Val Stream({
    generator => sub {
      return ValF $_ for grep defined, shift @source;
      return ErrF [ Name('NO_SUCH_VALUE') ];
    },
  });
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
      my $dres = await Dict->c_fx_make($scope, List \@dict_from);
    return $_ for not_ok +await Dict->destructure(
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
      return $_ for not_ok +await $scope->invoke_method_of(
        Escape($splat_to), assign => List[ List \@assign_from ]
      );
      return Val $from;
    }
    return $_ for not_ok +await $scope->invoke_method_of(
      Escape($to_slot), assign => List[ (shift @assign_from // ()) ]
    );
  }
  return Err [ Name('MISMATCH') ] if @assign_from;
  return Val $from;
}

1;
