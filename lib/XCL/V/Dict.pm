package XCL::V::Dict;

use curry;
use XCL::Class 'XCL::V';

with 'XCL::V::Role::Indexable';

sub index_is { 'String' }

async sub get ($self, $key) {
  my $dict = $self->data;
  Result({
    ($dict->{$key}
      ? (val => $dict->{$key})
      : (err => List([ Name('NO_SUCH_VALUE') => String($key) ]))
    ),
  });
}

sub set ($self, $key, $value) {
  return ValF($self->data->{$key} = $value);
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

async sub c_fx_make ($class, $scope, $lst) {
  return $_ for not_ok my $lres = await $scope->eval($lst);
  my %new;
  foreach my $pair ($lres->val->values) {
    if ($pair->is('Call') and $pair->metadata->{is_pair_proto}) {
      my $name = $pair->data->[1];
      return Err[ Name('NOT_NAME'), $name ] unless $name->is('Name');
      return $_ for not_ok my $res = await $scope->eval($name);
      $new{$name->data} = $res->val;
      next;
    }
    return Err([ Name('NOT_PAIR'), $pair ])
      unless $pair->is('List') and $pair->count == 2;
    return $_ for not_ok my $kres = await $pair->data->[0]->string;
    $new{$kres->val->data} = $pair->data->[1];
  }
  return Val Dict \%new;
}

sub f_pairs ($self, $) { ValF List [ $self->pairs ] }

sub f_to_list ($self, $) { ValF List [ $self->pairs ] }

sub f_keys ($self, $) { ValF List [ $self->keys ] }

sub f_values ($self, $) { ValF List [ $self->values ] }

sub c_f_concat ($class, $lst) {
  return $_ for $class->_same_types($lst);
  ValF Dict +{ map %{$_->data}, $lst->values };
}

sub to_perl ($self) {
  my %d = %{$self->data};
  +{ map +($_ => $d{$_}->to_perl), CORE::keys %d };
}

# possibly this should be exposed somehow

async sub destructure ($class, $scope, $lst) {
  my ($to, $from) = $lst->values;
  my @to_spec_p = $to->values;
  my %from = %{$from->data};
  my $splat_to;
  # pop off @pairs or @(%dict) or etc.
  if (@to_spec_p and my $last = $to_spec_p[-1]) {
    if ($last->is('Name') and $last->data eq '%') {
      $splat_to = 1;
      pop @to_spec_p;
    } elsif (
      ($last->is('Compound') or $last->is('Call'))
      and grep $_->is('Name') && $_->data eq '%',
            (my $last_call = $last->to_call)->data->[0]
    ) {
      die "WHAT" unless ((undef, $splat_to) = @{$last_call->data}) == 2;
      pop @to_spec_p;
    }
  }
  foreach my $to_spec_p (@to_spec_p) {
    # Valid are: :x, : x, :x(y), :x y, : x y
    die "WHAT" unless $to_spec_p->is('Call') or $to_spec_p->is('Compound');
    # convert to: [ : x ] [ [ : x ] y ] [ : x y ]
    my ($h, $t) = $to_spec_p->to_call->ht;
    # then: (:, x) or (:, x, y)
    my ($first, $key_p, $to_value) = (
      ($h->is('Call') ? $h->values : $h),
      $t->values
    );
    die "WHAT" unless $first->is('Name') and $first->data eq ':';
    unless ($to_value) {
      die "WHAT" unless $key_p->is('Name');
      return Err [ Name('MISMATCH') ]
        unless my $from_value = delete $from{$key_p->data};
      return $_ for not_ok +await dot_call_escape(
        $scope, $key_p, assign => $from_value
      );
      next;
    }
    # same logic as XCL::Builtins::Functions->c_fx_pair
    my $key = do {
      if ($key_p->is('Name')) {
        String($key_p->data);
      } else {
        return $_ for not_ok my $res = await $scope->eval($key_p);
        die "WHAT" unless (my $val = $res->val)->is('String');
        $val;
      }
    };
    return $_ for not_ok +await dot_call_escape(
      $scope, $to_value, assign => (delete($from{$key->data})//())
    );
  }
  return Err [ Name('MISMATCH') ] if CORE::keys(%from) and not $splat_to;
  if ($splat_to and ref($splat_to)) {
    return $_ for not_ok +await dot_call_escape(
      $scope, $splat_to, assign => Dict(\%from)
    );
  }
  return Val $from;
}

1;
