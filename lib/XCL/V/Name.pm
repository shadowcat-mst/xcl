package XCL::V::Name;

use XCL::Class 'XCL::V';

sub evaluate_against ($self, $scope) { $scope->get($self->data) }

sub display_data ($self, $) { $self->data }

sub f_name_to_string ($self, $) {
  ValF(String($self->data));
}

sub fx_assign ($self, $scope, $lst) {
  return ErrF [ Name('MISMATCH') ] unless my $val = $lst->head;
  return ValF $val if $self->data eq '$';
  return $scope->set($self->data, $val);
}

async sub fx_assign_via_call ($self, $scope, $lst) {
  my ($call_args, $val) = $lst->values;
  # this should use more clever typing but will do to begin with
  return Err [ Name('MISMATCH') ]
     unless $val and $val->is($self->data);
  return await dot_call_escape($scope, $call_args->head, assign => $val);
}

1;
