package XCL::V::Block;

use XCL::Class 'XCL::V';

async sub _invoke ($self, $scope, $) {
  my $iscope = $scope->snapshot;
  my $res;
  foreach my $stmt (@{$self->data}) {
    $res = await $iscope->eval($stmt);
    return $res unless $res->is_ok;
  }
  return $res;
}

sub display_data { '{...}' }

1;
