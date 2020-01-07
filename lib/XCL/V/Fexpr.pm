package XCL::V::Fexpr;

use XCL::Values;
use Mojo::Base 'XCL::V', -signatures;

sub invoke ($self, $outer_scope, $vals) {
  my ($argnames, $scope, $body) = @{$self->data}{qw(argnames scope body)};
  my %merge; @merge{@$argnames} = map Val($_), $outer_scope, $vals->values;
  $body->evaluate_against($scope->derive(\%merge));
}

sub display ($self, @) {
  return 'fexpr ('.join(', ', @{$self->data->{argnames}}).') { ... }';
}

1;
