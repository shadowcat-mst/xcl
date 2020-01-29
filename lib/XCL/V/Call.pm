package XCL::V::Call;

use Role::Tiny::With;
use XCL::Class 'XCL::V';

with 'XCL::V::Role::Listish';

sub evaluate_against ($self, $scope) {
  $self->_call($scope, @{$self->data});
}

sub _invoke ($self, $scope, $lst) {
  $self->_call($scope, @{$self->data}, $lst->values);
}

async sub _call {
  my ($self, $scope, $command, @args) = @_;
  my $res = await $scope->eval($command);
  return $res unless $res->is_ok;
  return await $res->val->invoke($scope, List(\@args));
}

sub display ($self, $depth) {
  return $self->SUPER::display(0) unless $depth;
  my $in_depth = $depth - 1;
  my @res;
  foreach my $val (@{$self->data}) {
    push @res, $val->display($in_depth);
  }
  return '[ '.join(' ', @res).' ]';
}

sub f_to_list ($self, $) {
  ValF List[ $self->values ];
}

1;
