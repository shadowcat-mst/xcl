package XCL::V::Call;

use XCL::Values;
use Role::Tiny::With;
use Mojo::Base 'XCL::V', -async, -signatures;

with 'XCL::V::Role::Listish';

sub evaluate_against ($self. $scope) {
  $self->_invoke($scope, @{$self->data});
}

sub invoke ($self. $scope, $lst) {
  $self->_invoke($scope, @{$self->data}, $lst->values);
}

async sub _invoke {
  my ($self, $scope, $command, @args) = @_;
  my $res = await $command->evaluate_against($scope);
  return $res unless $res->is_ok;
  return $res->val->invoke($scope, List(\@args));
}

sub display ($self, $depth) {
  return $self->SUPER::display(0) unless $depth;
  my $in_depth = $depth - 1;
  my @res;
  foreach my $val ($self->data->values) {
    push @res, $val->display($in_depth);
  }
  return '[ '.join(' ', @res).' ]';
}

1;
