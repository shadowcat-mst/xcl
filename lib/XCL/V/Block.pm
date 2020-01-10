package XCL::V::Block;

use Mojo::Base 'XCL::V', -async;

async sub invoke {
  my ($self, $scope, undef) = @_;
  my $iscope = $scope->snapshot;
  my $res;
  foreach my $stmt (@{$self->data}) {
    $res = await $iscope->eval($stmt);
    return $res unless $res->is_ok;
  }
  return $res;
}

sub display { '{...}' }

1;
