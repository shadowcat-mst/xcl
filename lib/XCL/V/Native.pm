package XCL::V::Native;

use XCL::Class 'XCL::V';

async sub _invoke {
  my ($self, $scope, $valp) = @_;
  my ($ns, $method_name, $apply, $is_method, $unwrap, $res)
    = @{$self->data}{qw(ns native_name apply is_method unwrap)};
  require join('/', split '::', $ns).".pm" if $ns;
  my ($vals) = map +($unwrap ? $_->tail : $_), !$apply ? $valp
    : not_ok($res = await $scope->eval($valp)) ? return $res : $res->val;
  if ($is_method) {
    return Err[ Name('WRONG_ARG_COUNT') => Int(0) ]
      unless my ($first, $rest) = $vals->ht;
    my $fval = $apply ? $first
      : not_ok($res = await $scope->eval($first)) ? return $res : $res->val;
    return await $fval->$method_name($apply ? () : $scope, $rest);
  }
  return await $ns->$method_name($scope, $vals);
}

1;
