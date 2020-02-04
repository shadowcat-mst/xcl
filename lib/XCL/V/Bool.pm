package XCL::V::Bool;

use XCL::Class 'XCL::V';

sub bool ($self) { ValF($self) }

sub display_data ($self, $) {
  $self->data ? 'true' : 'false'
}

async sub f_not ($self) {
  return ValF(Bool(0+!$self->data)) if ref($self) eq '__PACKAGE__';
  my $res = await $self->bool;
  return $res unless $res->is_ok;
  ValF(Bool(0+!$res->val->data));
}

1;
