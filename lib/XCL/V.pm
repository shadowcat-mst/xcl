package XCL::V;

use XCL::Class;

has [ qw(data metadata) ];

sub but ($self, @args) { ref($self)->new(%$self, @args) }

sub of_data ($self, $data) { $self->new(data => $data, metadata => {}) }

sub evaluate_against ($self, $) { ValF($self) }

async sub invoke ($self, $scope, $lst) {
  state $state_id = '000';
  my $op_id = ++$state_id;
  # theoretically harmless but complicated life before, await more tests
  #return await $self->_invoke($scope, $lst) unless DEBUG;
  my $is_basic = do {
    state %is_basic;
    $is_basic{ref($self)} //= 0+!!(
      ref($self)->can('_invoke')
        eq XCL::V->can('_invoke')
    )
  };

  return Val $self if $is_basic && !$lst->values;

  dynamically $Eval_Depth = $Eval_Depth + 1;

  my $indent = '  ' x $Eval_Depth;
  my $prefix = "${indent}call "; # $op_id ";
  if ($Eval_Depth and not $Did_Thing) {
    print STDERR " {\n" if DEBUG;
    $Did_Thing++;
  }

  print STDERR $prefix.$self->display(DEBUG).' '.$lst->display(DEBUG) if DEBUG;
  my $res = do {
    dynamically $Did_Thing = 0;
    my $tmp = await $self->_invoke($scope, $lst);
    print STDERR "${indent}\}" if DEBUG and $Did_Thing;
    $tmp;
  };
  print STDERR " ->\n${indent}  ".$res->display(DEBUG).";\n" if DEBUG;
  return $res;
}

sub _invoke ($self, $scope, $lst) {
  # Was seriously wondering if this should always just be an error.
  return ErrF([ Name('CANT_INVOKE'), String($self->type) ]);
  # Try letting this code run again if we find a reason
  return ValF $self unless my @vals = $lst->values;
  ErrF([
    Name('WRONG_ARG_COUNT')
    => String($self->display(0))
    => Int(scalar @vals)
  ]);
}

sub is ($self, $type) {
  $self->isa("XCL::V::${type}");
}

sub type ($self) {
  (split '::', ref($self))[-1];
}

sub display ($self, $depth) {
  my $data = $self->display_data($depth);
  return $data unless keys %{$self->metadata};
  return $data if $depth >= 0 and $depth <= 2;
  return $data.' with_meta '.(Dict $self->metadata)->display($depth-2);
}

sub display_data ($self, $) { $self->type.'()' }

sub bool ($self) { ErrF([ Name('CANT_BOOLEAN') => String($self->type) ]) }

sub string ($self) { ErrF([ Name('CANT_STRINGIFY') => String($self->type) ]) }

# maybe doesn't belong here but in a role but shrug

sub _same_types ($self, $lst, $type = $self->type) {
  if (grep $_->type ne $type, $lst->values) {
    return ErrF([
      Name('TYPES_MUST_MATCH') => map String($_->type), ($self, $lst->values)
    ]);
  }
  return ();
}

sub DESTROY ($self) {
  return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
  return unless my $drop = $self->metadata->{drop};
  $drop->invoke(Scope({}), List $self);
  return;
}

sub make ($proto, $data, $metadata = {}) {
  $proto->new(data => $data, metadata => $metadata);
}

sub to_perl ($self) { $self }

sub from_perl ($class, $value) {
  my $ref = ref($value);
  if ($ref eq 'HASH') {
    return Dict({
      map +($_ => $class->from_perl($value->{$_})),
        keys %$value
    });
  }
  if ($ref eq 'ARRAY') {
    return List([ map $class->from_perl($_), @$value ]);
  }
  return $value if $ref;
  no warnings 'numeric';
  if (
    !utf8::is_utf8($value)
    && length((my $dummy = '') & $value)
    && 0 + $value eq $value
    && $value * 0 == 0
  ) {
    return $value =~ /\./ ? Float($value) : Int($value);
  }
  return String($value);
}

sub fx_or ($self, $scope, $lst) { $self->_fx_bool($scope, $lst, 0) }
sub fx_and ($self, $scope, $lst) { $self->_fx_bool($scope, $lst, 1) }

async sub _fx_bool ($self, $scope, $lst, $check) {
  my $bres = await $self->bool;
  return $bres unless $bres->is_ok;
  return Val $self if $bres->val->data != $check;
  return await $scope->eval($lst->data->[0]);
}

1;
