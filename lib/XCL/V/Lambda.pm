package XCL::V::Lambda;

use Role::Tiny::With;
use XCL::Class 'XCL::V::Fexpr';

sub _invoke_values ($self, $scope, $vals) {
  return $scope->eval($vals);
}

sub display_data ($self, $) {
  return 'lambda '.$self->data->{argspec}->display(3).' { ... }';
}

# Only necessary because builtin code doesn't walk isa yet
sub c_fx_make { shift->SUPER::c_fx_make(@_) }

1;
