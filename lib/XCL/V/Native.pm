package XCL::V::Native;

use XCL::Class 'XCL::V';

async sub _invoke ($self, $scope, $valp) {
  my ($ns, $method_name, $apply, $is_method, $unwrap, $res)
    = @{$self->data}{qw(ns native_name apply is_method unwrap)};
  require join('/', split '::', $ns).".pm" if $ns;
  my ($vals) = map (
    $apply
      ? (not_ok($res = await $scope->eval($_)) ? return $res : $res->val)
      : $_
  ), map +($unwrap ? $_->tail : $_), $valp;
  if ($is_method) {
    return Err[ Name('WRONG_ARG_COUNT') => Int(0) ]
      unless my ($first, $rest) = $vals->ht;
    my $fval = $apply ? $first
      : not_ok($res = await $scope->eval($first)) ? return $res : $res->val;
    return await $fval->$method_name($apply ? () : $scope, $rest);
  }
  return await $ns->$method_name($scope, $vals);
}

sub display_data ($self, $depth) {
  return $self->SUPER::display_data(0) unless $depth;
  my $in_depth = $depth - 1;
  my $dproto = $self->data;
  my $data = { %{$dproto}{grep $dproto->{$_}, keys %$dproto} };
  return 'Native('.XCL::V->from_perl($data)->display($in_depth).')';
}

1;
