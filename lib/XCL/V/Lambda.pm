package XCL::V::Lambda;

use Role::Tiny::With;
use XCL::Class 'XCL::V::Fexpr';

async sub _invoke {
  my ($self, $scope, $vals) = @_;
  my $res = await $scope->eval($vals);
  return $res unless $res->is_ok;
  return await $self->SUPER::_invoke($scope, $res->val);
}

sub display ($self, @) {
  return 'lambda ('.join(', ', @{$self->data->{argnames}}).') { ... }';
}

1;
