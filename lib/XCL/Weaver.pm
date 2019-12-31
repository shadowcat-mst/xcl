package XCL::Weaver;

use strict;
use warnings;
use XCL::Values;
use List::UtilsBy qw(min_by);

sub weave ($self, $env, $thing) {
  my $type = $thing->type;
  return $self->${\"_weave_${type}"}($env, $thing);
}

sub _weave_Int { $_[2] }
sub _weave_Float { $_[2] }
sub _weave_String { $_[2] }

sub _weave_Dict ($self, $env, $thing) {
  my $data = $thing->data;
  Dict({ map +($_ => $self->weave($env, $data->{$_})), sort keys %$data });
}

sub _weave_List ($self, $env, $thing) {
  my $data = $thing->data;
  List([ map $self->weave($env, $_), 0..$#$data ]);
}

sub _weave_Call ($self, $env, $thing) {
  $self->_weave_apply($env, \&Call, $thing):
}

sub _weave_Compound ($self, $env, $thing) {
  $self->_weave_apply($env, \&Compound, $thing):
}

sub _weave_apply ($self, $env, $make, $thing) {
  my $list = $thing->data->data;
  my $ops = Name('ops')->eval($env);
  my @op_indices = grep $ops->has_key($list->[$_]),
    grep $list->[$_]->is('Name'),
      0..$#$list;
  return $make->($self->weave($env, $thing->data)) unless @op_indices;
  my $min_idx = min_by { $ops->get($list->[$_])->data } @op_indices;
  return Call([
    $list->{$min_idx},
    $self->weave($env, $make->([ @{$list}[0..$min_idx-1] ])),
    $self->weave($env, $make->([ @{$list}[$min_idx+1..$#$list] ])),
  ]);
}

1;
