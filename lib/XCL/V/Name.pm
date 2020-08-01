package XCL::V::Name;

use XCL::Class 'XCL::V';

sub evaluate_against ($self, $scope) {
  $scope->combine($scope, List[String $self->data]);
}

sub display_data ($self, $) { $self->data }

sub f_name_to_string ($self, $) {
  ValF(String($self->data));
}

async sub fx_assign ($self, $scope, $lst) {
  return Err [ Name('MISMATCH') ] unless my $val = $lst->head;
  return Val $val if $self->data eq '$';
  return $_ for not_ok +await $scope->invoke_method_of(
    $scope, assign_via_call => List[ List([String($self->data)]), Escape $val ]
  );
  return Val $val;
}

async sub fx_assign_via_call ($self, $scope, $lst) {
  my ($call_args, $val) = $lst->values;
  # this should use more clever typing but will do to begin with
  return Err [ Name('MISMATCH') ]
     unless $val and $val->is($self->data);
  # Escape shouldn't be necessary here - is something eval-ing pointlessly?
  return await $scope->invoke_method_of(Escape($call_args->head), assign => List[$val]);
}

1;
