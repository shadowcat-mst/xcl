package XCL::V::PerlObject;

use constant CODULATE => '(&{}';
use XCL::Class 'XCL::V';

sub bool ($self) { ValF True }

sub display_data ($self, $) { 'PerlObject('.$self->data.')' }

sub _make_perl_call ($method) {
  Native->from_foreign(
    $method =~ s/^list_//
      ? sub { [ shift->$method(@_) ] }
      : sub { shift->$method(@_) }
  );
}

sub from_perl ($class, $obj) {
  my $has_methods = Native->from_foreign(\&_make_perl_call);
  $class->new(data => $obj, metadata => { has_methods => $has_methods });
}

sub to_perl { shift->data }

sub can_invoke ($self) { 0+!!$self->can(CODULATE) }

sub invoke_against ($self, $scope, $vals) {
  $self->SUPER::_invoke($scope, $vals) unless $self->can_invoke;
  _make_perl_call($self->data->${\+CODULATE})->invoke($scope, $vals);
}

1;

