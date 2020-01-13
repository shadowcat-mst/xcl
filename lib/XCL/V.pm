package XCL::V;

use Future; # needs to be somewhere
use XCL::Values;
use Mojo::Base -base, -signatures, -async;
use utf8 ();

has [ qw(data metadata) ];

sub but ($self, @args) { ref($self)->new(%$self, @args) }

sub evaluate_against ($self, $) { Val($self) }

sub invoke ($self, $, $) {
  Err([ Name('CANT_INVOKE') => String($self->display) ])
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
  $drop->invoke(Scope({}), $self);
  return;
}

sub make ($proto, $data, $metadata = {}) {
  $proto->new(data => $data, metadata => $metadata);
}

sub to_perl ($self) { $self }

sub from_perl ($class, $value) {
  my $ref = ref($value);
  if ($ref eq 'HASH') {
    return Dict({ map +($_ => $class->from_perl($value->{$_})), @$value });
  }
  if ($ref eq 'ARRAY') {
    return List([ map $class->from_perl($_), @$value ]);
  }
  return $value if $ref;
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
  return $self if $bres->val->data != $check;
  return await $scope->eval($lst->data->[0]);
}

1;
