package XCL::V::Role::Indexable;

use XCL::Class -role;

requires 'index_is';

async sub invoke_against ($self, $scope, $lst) {
  return $_ for not_ok my $vres = await $scope->eval_concat($lst);
  my $type = $self->index_is;
  return Err([ Name('WRONG_ARG_COUNT') => Int(scalar $vres->val->values) ])
    unless (my ($index) = $vres->val->values) == 1;
  return Err([ Name('NOT_A_'.uc($type)) => String($index->type) ])
    unless $index->is($type);
  await $self->get($index);
}

1;
