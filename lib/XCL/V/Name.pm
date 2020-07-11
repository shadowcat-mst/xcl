package XCL::V::Name;

use XCL::Class 'XCL::V';

sub evaluate_against ($self, $scope) {
  $scope->invoke($scope, List[String $self->data]);
}

sub display_data ($self, $) { $self->data }

sub f_name_to_string ($self, $) {
  ValF(String($self->data));
}

async sub fx_assign ($self, $scope, $lst) {
  return Err [ Name('MISMATCH') ] unless my $val = $lst->head;
  return Val $val if $self->data eq '$';
  return $_ for not_ok +await concat dot_call_escape(
    $scope, $scope, assign_via_call => List([String($self->data)]), Escape $val
  );
  return Val $val;
}

async sub fx_assign_via_call ($self, $scope, $lst) {
  my ($call_args, $val) = $lst->values;
  # this should use more clever typing but will do to begin with
  return Err [ Name('MISMATCH') ]
     unless $val and $val->is($self->data);
  return await concat dot_call_escape($scope, $call_args->head, assign => $val);
}

1;
