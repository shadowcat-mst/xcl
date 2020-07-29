package XCL::V::Curry;

use XCL::Class 'XCL::V';

sub invoke_against ($self, $scope, $lst) {
  my ($inv, @args) = @{$self->data};
  $scope->combine($inv, List[ @args, $lst->values ]);
}

sub f_concat ($self, $lst) {
  return $_ for $self->_same_types($lst, 'List');
  ValF Curry([ $self, map $_->values, $lst->values ]);
}

1;
