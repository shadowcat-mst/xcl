package XCL::V::Block;

use XCL::Class 'XCL::V';

async sub invoke_against ($self, $scope, $lst) {
  my $iscope = do {
    if (my ($this) = $lst->values) {
      $scope->derive({
        this => Val($this),
        # should probably convert this to direct c_fx_dot + Curry
        '$.' => Val(Call [ Name('.'), $this ]),
      });
    } else {
      $scope->snapshot;
    }
  };
  my $res;
  foreach my $stmt (@{$self->data}) {
    $res = await $iscope->eval($stmt);
    return $res unless $res->is_ok;
  }
  return $res;
}

sub display_data ($self, $depth) {
  join "\n", '{',
    (map '  '.$_->display($depth-1).';', @{$self->data}),
  '}', '';
}

1;
