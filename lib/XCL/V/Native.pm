package XCL::V::Native;

use Mojo::Base 'XCL::V', -signatures;

sub invoke ($self, $scope, $vals) {
  $self->data->($scope, @{$vals->data});
}

1;
