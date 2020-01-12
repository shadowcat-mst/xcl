package XCL::Weaver;

use XCL::Values;
use List::UtilsBy qw(min_by);
use Mojo::Base -base, -signatures;

has reifier => sub {
  require XCL::Reifier;
  XCL::Reifier->new;
};

has 'scope';

has _ops => sub ($self) {
  return {} unless my $scope = $self->scope;
  my $ops_raw = $scope->get('_OPS')->val->data;
  # should check all Int here
  my %ops = map +($_ => $ops_raw->{$_}->data), sort keys %$ops_raw;
  \%ops
};

sub parse ($self, $type, $str) {
  $self->weave($self->reifier->parse($type, $str));
}

sub weave ($self, $thing) {
  my $type = $thing->type;
  return $self->${\"_weave_${type}"}($thing);
}

sub _weave_Int ($self, $thing) { $thing }
sub _weave_Float ($self, $thing) { $thing }
sub _weave_String ($self, $thing) { $thing }
sub _weave_Name ($self, $thing) { $thing }

sub _weave_Dict ($self, $thing) {
  my $data = $thing->data;
  $thing->make({ map +($_ => $self->weave($data->{$_})), sort keys %$data });
}

sub _weave_List ($self, $thing) {
  $thing->make([ map $self->weave($_), $thing->values ])
}

sub _weave_Call ($self, $thing) {
  $self->_weave_apply($thing);
}

sub _weave_Compound ($self, $thing) {
  $self->_weave_apply($thing);
}

sub _weave_apply ($self, $thing) {
  my @list = @{$thing->data};
  my $ops = $self->_ops;
  my @op_indices = grep exists $ops->{$list[$_]},
    grep $list[$_]->is('Name'),
      0..$#list;
  return $thing->make([ map $self->weave($_), @list ]) unless @op_indices;
  my $min_idx = min_by { $ops->{$list[$_]->data} } @op_indices;
  if ($min_idx > 0) {
    splice(
      @list, $min_idx - 1, 3,
      Call([ @list[ $min_idx, $min_idx - 1, $min_idx + 1 ] ])
    );
    return Call(\@list);
  }
  return Call([
    $list[$min_idx],
    $self->weave($self->make([ @list[0..$min_idx-1] ])),
    $self->weave($self->make([ @list[$min_idx+1..$#list] ])),
  ]);
}

sub _weave_Block ($self, $thing) {
  Block([ map $self->weave($_), @{$thing->data} ]);
}

1;
