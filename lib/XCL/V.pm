package XCL::V;

use XCL::Builtins::Builder;
use Scalar::Util ();
use XCL::Class;

has 'data';
has metadata => sub { {} };

sub new_with_methods ($class, @rest) {
  my $new = $class->new(@rest);
  $new->metadata->{dot_methods}
    ||= Dict XCL::Builtins::Builder::_builtins_of($class);
  $new;
}

sub but ($self, @args) { ref($self)->new(%$self, @args) }

sub of_data ($self, $data) { $self->new(data => $data, metadata => {}) }

sub evaluate_against ($self, $) { ValF($self) }

async sub invoke ($self, $scope, @lst) {
  my $lst = $lst[0]//List[];
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
  dynamically $Am_Running = [ Name('invoke') => $self, $lst ];

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

sub can_invoke ($self) {
  my $class = ref($self) || $self;
  state %can_invoke;
  state $me = __PACKAGE__->can('_invoke');
  $can_invoke{$class} //= 0+!!($me ne $class->can("_invoke"));
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

sub must_be ($self, $type) {
  die "${self} is not of ${type}" unless $self->is($type);
  $self;
}

sub type ($self) {
  (split '::', ref($self)||$self)[-1];
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
  return unless my $drop = ($self->metadata||{})->{drop};
  $drop->invoke(Scope({}), List $self);
  return;
}

sub make ($proto, $data, $metadata = {}) {
  $proto->new(data => $data, metadata => $metadata);
}

sub to_perl ($self) { $self }

sub from_perl ($class, $value) {
  die "Can't inflate undef" unless defined($value);
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
  if ($ref eq 'CODE') {
    return Native->from_foreign($value);
  }
  if (Scalar::Util::blessed $value) {
    return $value if $value->isa('XCL::V');
    return XCL::V::PerlObject->from_perl($value);
  }
  die "Can't inflate reftype ${ref} to perl" if $ref;
  no warnings 'numeric';
  my $is_utf8 = utf8::is_utf8($value);
  if (
    !$is_utf8
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

async sub fx_where ($self, $scope, $lst) {
  return $_ for not_ok my $lres = await $scope->eval($lst);
  my ($where) = $lres->val->values;
  my $res = await $where->invoke($scope, List[$self]);
  return $_ for not_ok_except NO_SUCH_VALUE => $res;
  return Val List[] unless $res->is_ok;
  return $_ for not_ok my $bres = await $res->val->bool;
  return Val List[$bres->val->data ? ($self) : ()];
}

sub fx_maybe ($self, $scope, $lst) {
  return XCL::Builtins::Functions->c_fx_maybe(
    $scope, List[ $lst->values, $self ]
  );
}

sub fx_exists ($self, $scope, $lst) {
  return XCL::Builtins::Functions->c_fx_exists(
    $scope, List[ $lst->values, $self ]
  );
}

1;
