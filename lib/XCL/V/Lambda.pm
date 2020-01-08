package XCL::V::Lambda;

use XCL::Values;
use Role::Tiny::With;
use Mojo::Base 'XCL::V', -signatures, -async;

with 'XCL::V::Role::Callable';

async sub invoke {
  my ($self, $outer_scope, $vals) = @_;
  my ($argnames, $scope, $body) = @{$self->data}{qw(argnames scope body)};
  my $argvalres = await $vals->evaluate_against($outer_scope);
  return $argvalres unless $argvalres->is_ok;
  my %merge; @merge{@$argnames} = map Val($_), $argvalres->val->values;
  $body->evaluate_against($scope->derive(\%merge));
}

sub display ($self, @) {
  return 'lambda ('.join(', ', @{$self->data->{argnames}}).') { ... }';
}

1;
