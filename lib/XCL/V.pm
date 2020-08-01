package XCL::V;

use Scalar::Util ();
use XCL::Class;

has 'data';
has metadata => sub { {} };

sub new_with_methods ($class, @rest) {
  state $loaded = require XCL::Builtins::Builder;
  my $new = $class->new(@rest);
  $new->metadata->{has_methods}
    ||= Dict XCL::Builtins::Builder::_builtins_of($class);
  $new;
}

sub but ($self, @args) { ref($self)->new(%$self, @args) }

sub of_data ($self, $data) { $self->new(data => $data, metadata => {}) }

sub evaluate_against ($self, $) { ValF($self) }

sub can_invoke ($self) {
  my $class = ref($self) || $self;
  state %can_invoke;
  state $me = __PACKAGE__->can('invoke_against');
  $can_invoke{$class} //= 0+!!($me ne $class->can('invoke_against'));
}

sub invoke_against ($self, $scope, $lst) {
  # Was seriously wondering if this should always just be an error.
  # return ErrF([ Name('CANT_INVOKE'), String($self->type) ]);
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
  return $self->display_data($depth);

  my $data = $self->display_data($depth);
  return $data unless keys %{$self->metadata};
  return $data if $depth >= 0 and $depth <= 2;
  return $data.' with_meta '.(Dict $self->metadata)->display($depth-2);
}

sub display_data ($self, $) { $self->type.'()' }

sub bool ($self) {
  ErrF([ Name('CANT_BOOLEAN') => $self ])
}

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
  Scope({})->combine($drop, List[$self]);
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
  my $res = await $scope->combine($where, List[$self]);
  return $_ for not_ok_except NO_SUCH_VALUE => $res;
  return Val List[] unless $res->is_ok;
  return $_ for not_ok my $bres = await $res->val->bool;
  return Val List[$bres->val->data ? ($self) : ()];
}

sub fx_maybe ($self, $scope, $lst) {
  state $loaded = require XCL::Builtins::Functions;
  return XCL::Builtins::Functions->c_fx_maybe(
    $scope, List[ $lst->values, $self ]
  );
}

sub fx_exists ($self, $scope, $lst) {
  state $loaded = require XCL::Builtins::Functions;
  return XCL::Builtins::Functions->c_fx_exists(
    $scope, List[ $lst->values, $self ]
  );
}

async sub fx_assign ($self, $scope, $lst) {
  return Err[ Name('MISMATCH') ] unless my ($val) = $lst->values;
  return $_ for not_ok_except NO_SUCH_METHOD_OF =>
    my $res = await $scope->invoke_method_of(
      $self, 'eq' => List[$val]
    );
  return Err[ Name('MISMATCH') ] unless $res->is_ok and $res->val->data;
  return Val List($val);
}

1;
