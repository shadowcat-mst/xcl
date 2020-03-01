package XCL::V::Compound;

use XCL::Class 'XCL::V';

async sub evaluate_against ($self, $scope) {
  my ($val, @rest) = @{$self->data};
  my $res = await $scope->eval($val);
  return $res unless $res->is_ok;
  foreach my $step (@rest) {
    $res = await $res->val->invoke(
             $scope, $step->is('List') ? $step : List [$step]
           );
    return $res unless $res->is_ok;
  }
  return $res;
}

sub display_data ($self, $depth) {
  join '', map $_->display($depth), @{$self->data};
}

1;
