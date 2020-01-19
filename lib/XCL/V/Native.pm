package XCL::V::Native;

use XCL::Class 'XCL::V';

sub invoke ($self, $scope, $vals) {
  $self->data->($scope, @{$vals->data});
}

1;
