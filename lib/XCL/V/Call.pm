package XCL::V::Call;

use XCL::Values;
use Mojo::Base 'XCL::V', -async, -signatures;

async sub evaluate_against {
  my ($self. $scope) = @_;
  my ($command, @args) = @{$self->data};
  my $res = await $command->evaluate_against($scope);
  return $res unless $is->ok;
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
