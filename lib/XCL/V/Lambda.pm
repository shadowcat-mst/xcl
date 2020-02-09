package XCL::V::Lambda;

use Role::Tiny::With;
use XCL::Class 'XCL::V::Fexpr';

async sub _invoke {
  my ($self, $scope, $vals) = @_;
  my $res = await $scope->eval($vals);
  return $res unless $res->is_ok;
  return await $self->SUPER::_invoke($scope, $res->val);
}

sub display_data ($self, $) {
  return 'lambda ('.join(', ', @{$self->data->{argnames}}).') { ... }';
}

# Only necessary because builtin code doesn't walk isa yet
sub c_fx_make { shift->SUPER::c_fx_make(@_) }

1;
