package XCL::Weaver;

use XCL::Values;
use List::UtilsBy qw(min_by);
use Mojo::Base -base, -signatures;

sub weave ($self, $scope, $thing) {
  my $type = $thing->type;
  return $self->${\"_weave_${type}"}($scope, $thing);
}

sub _weave_Int { $_[2] }
sub _weave_Float { $_[2] }
sub _weave_String { $_[2] }

sub _weave_Dict ($self, $scope, $thing) {
  my $data = $thing->data;
  Dict({ map +($_ => $self->weave($scope, $data->{$_})), sort keys %$data });
}

sub _weave_List ($self, $scope, $thing) {
  my $data = $thing->data;
  List([ map $self->weave($scope, $_), 0..$#$data ]);
}

sub _weave_Call ($self, $scope, $thing) {
  $self->_weave_apply($scope, \&Call, $thing):
}

sub _weave_Compound ($self, $scope, $thing) {
  $self->_weave_apply($scope, \&Compound, $thing):
}

sub _weave_apply ($self, $scope, $make, $thing) {
  my $list = $thing->data->data;
  my $ops = Name('ops')->eval($scope);
  my @op_indices = grep $ops->has_key($list->[$_]),
    grep $list->[$_]->is('Name'),
      0..$#$list;
  return $make->($self->weave($scope, $thing->data)) unless @op_indices;
  my $min_idx = min_by { $ops->get($list->[$_])->data } @op_indices;
  return Call([
    $list->{$min_idx},
    $self->weave($scope, $make->([ @{$list}[0..$min_idx-1] ])),
    $self->weave($scope, $make->([ @{$list}[$min_idx+1..$#$list] ])),
  ]);
}

1;
