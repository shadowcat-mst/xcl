package XCL::V;

use XCL::Class;

has [ qw(data metadata) ];

sub but ($self, @args) { ref($self)->new(%$self, @args) }

sub of_data ($self, $data) { $self->new(data => $data, metadata => {}) }

sub evaluate_against ($self, $) { ValF($self) }

async sub invoke ($self, $scope, $lst) {
  state $state_id = '000';
  my $op_id = ++$state_id;
  return await $self->_invoke($scope, $lst) unless DEBUG;
  my $is_basic = do {
    state %is_basic;
    $is_basic{ref($self)} //= 0+!!(
      ref($self)->can('_invoke')
        eq XCL::V->can('_invoke')
    )
  };

  return Val $self if $is_basic && !$lst->values;

  my $this_depth = $Eval_Depth + 1;
  dynamically $Eval_Depth = $this_depth;

  my $prefix = ('  ' x $Eval_Depth)."C_${op_id}_";


  print STDERR "${prefix}E: ".$self->display(-1).': '.$lst->display(-1)."\n";
  my $res = await $self->_invoke($scope, $lst);
  print STDERR "${prefix}R: ".$self->display(-1).': '.$res->display(-1)."\n";
  return $res;
}

sub _invoke ($self, $scope, $lst) {
  return ValF $self unless my @vals = $lst->values;
  ErrF([
    Name('WRONG_ARG_COUNT')
    => String($self->display)
    => Int(scalar @vals)
  ]);
}

sub is ($self, $type) {
  $self->isa("XCL::V::${type}");
}

sub type ($self) {
  (split '::', ref($self))[-1];
}

sub display ($self, @) { $self->type.'()' }

sub bool ($self) { ErrF([ Name('CANT_BOOLEAN') => String($self->type) ]) }

sub string ($self) { Err([ Name('CANT_STRINGIFY') => String($self->type) ]) }

# maybe doesn't belong here but in a role but shrug

sub _same_types ($self, $lst, $type = $self->type) {
  if (grep $_->type ne $type, $lst->values) {
    return ErrF([
      Name('TYPES_MUST_MATCH') => map String($_->type), ($self, $lst->values)
    ]);
  }
  return ();
}

sub DESTROY {
  my ($self) = @_;
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

async sub _fx_bool {
  my ($self, $scope, $lst, $check) = @_;
  my $bres = await $self->bool;
  return $bres unless $bres->is_ok;
  return Val $self if $bres->val->data != $check;
  return await $scope->eval($lst->data->[0]);
}

1;
