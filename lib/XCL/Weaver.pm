package XCL::Weaver;

use List::UtilsBy qw(min_by);
use XCL::Class;

has reifier => sub {
  require XCL::Reifier;
  XCL::Reifier->new;
};

has ops => sub { {} };

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
  $self->_weave_apply($thing, $thing->values);
}

sub _weave_Compound ($self, $thing) {
  my @data = @{$thing->data};
  return $self->weave($data[0]) if @data == 1;
  $self->_weave_apply($thing, @data);
}

sub _weave_expr ($self, $thing, @exp) {
  return $self->weave($exp[0]) if @exp == 1;
  $self->_weave_apply($thing, @exp);
}

sub _weave_apply ($self, $thing, @list) {
  return $thing->make([ map $self->weave($_), @list ]) unless @list > 2;
  my $ops = $self->ops;
  my @op_indices = 
      grep $list[$_]->is('Name') && exists $ops->{$list[$_]->data},
        1..($#list-1);
  return $thing->make([ map $self->weave($_), @list ]) unless @op_indices;
  my @min_idxes = min_by { $ops->{$list[$_]->data}[0] } @op_indices;
  my ($prec, $assoc, $reverse) = @{$ops->{$list[$min_idxes[0]]->data}};
  $assoc //= 0;
  if ($prec > 0) {
    my $min_idx = $min_idxes[$assoc];
    splice(
      @list, $min_idx - 1, 3,
      Call([ @list[ $min_idx, $min_idx - 1, $min_idx + 1 ] ])
    );
    return $self->_weave_expr($thing, @list);
  }
  my $min_idx = $min_idxes[$assoc];
  my @sides = (
    $self->_weave_expr($thing, @list[0..$min_idx-1]),
    $self->_weave_expr($thing, @list[$min_idx+1..$#list]),
  );
  return Call([
    $list[$min_idx],
    $reverse ? reverse(@sides) : @sides
  ]);
}

sub _weave_Block ($self, $thing) {
  Block([ map $self->weave($_), @{$thing->data} ]);
}

1;
