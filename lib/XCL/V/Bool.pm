package XCL::V::Bool;

use XCL::Class 'XCL::V';

sub bool ($self) { ValF($self) }

sub display_data ($self, $) {
  $self->data ? 'true' : 'false'
}

async sub c_fx_not ($self, $scope, $lst) {
  return $_ for not_ok my $vres = await concat $scope->f_expr($lst);
  my $val = $vres->val;
  return Val(Bool(0+!$val->data)) if ref($val) eq '__PACKAGE__';
  my $res = await concat $val->bool;
  return $res unless $res->is_ok;
  Val(Bool(0+!$res->val->data));
}

sub f_eq ($self, $lst) {
  return $_ for $self->_same_types($lst);
  return ValF Bool 0+($self->data == $lst->head->data);
}

1;
