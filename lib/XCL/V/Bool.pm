package XCL::V::Bool;

use XCL::Class 'XCL::V';

sub bool ($self) { ValF($self) }

sub display_data ($self, $) {
  $self->data ? 'true' : 'false'
}

async sub c_f_not ($self, $lst) {
  my ($val) = $lst->values;
  return ValF(Bool(0+!$val->data)) if ref($val) eq '__PACKAGE__';
  my $res = await $val->bool;
  return $res unless $res->is_ok;
  ValF(Bool(0+!$res->val->data));
}

1;
