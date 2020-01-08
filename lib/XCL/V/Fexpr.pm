package XCL::V::Fexpr;

use XCL::Values;
use Role::Tiny::With;
use Mojo::Base 'XCL::V', -signatures;

with 'XCL::V::Role::Callable';

sub invoke ($self, $outer_scope, $vals) {
  my ($argnames, $scope, $body) = @{$self->data}{qw(argnames scope body)};
  my %merge; @merge{@$argnames} = map Val($_), $outer_scope, $vals->values;
  $body->evaluate_against($scope->derive(\%merge));
}

sub display ($self, @) {
  return 'fexpr ('.join(', ', @{$self->data->{argnames}}).') { ... }';
}

1;
