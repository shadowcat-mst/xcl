package XCL::V::Lambda;

use XCL::Values;
use Role::Tiny::With;
use Mojo::Base 'XCL::V::Fexpr', -signatures, -async;

async sub invoke {
  my ($self, $scope, $vals) = @_;
  my $res = await $scope->eval($vals);
  return $res unless $res->is_ok;
  return await $self->SUPER::invoke($scope, $res->val);
}

sub display ($self, @) {
  return 'lambda ('.join(', ', @{$self->data->{argnames}}).') { ... }';
}

1;
