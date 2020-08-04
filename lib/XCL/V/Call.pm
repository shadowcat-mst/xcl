package XCL::V::Call;

use XCL::Class 'XCL::V';

with 'XCL::V::Role::Listish';

sub evaluate_against ($self, $scope) {
  $self->_call($scope, @{$self->data});
}

sub invoke_against ($self, $scope, $lst) {
  $self->_call($scope, @{$self->data}, $lst->values);
}

async sub _call ($self, $scope, $command_p, @args) {
  return $_ for not_ok my $res = await $scope->eval_concat(List[$command_p]);
  my ($command, @rest) = $res->val->values;
  return await $scope->combine($command, List[ @rest, @args ]);
}

sub display_data ($self, $depth) {
  return $self->SUPER::display_data(0) unless $depth;
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

async sub fx_assign ($self, $scope, $lst) {
  my ($head, $tail) = $self->ht;
  return $_ for not_ok my $res = await $scope->eval_concat(List[$head]);
  my ($command, @rest) = $res->val->values;
  return $_ for not_ok_except NO_SUCH_METHOD_OF =>
    my $lres = await $scope->lookup_method_of($command, 'assign_via_call');
  if ($lres->is_ok) {
    # fall through only if assign_via_call explicitly declines to try
    return $_ for not_ok_except MISMATCH =>
      my $res = await $scope->combine(
        $lres->val, List[$command, List([@rest, $tail->values]), $lst->values]
      );
    return $res if $res->is_ok;
  }
  die "WHAT" if @rest;
  #return $_ for not_ok
  #  my $cres = await $scope->combine($command, List \@rest);
  return await $scope->invoke_method_of($res->val, assign => $lst);
}

sub to_call ($self) { $self }

sub f_to_call ($self, $) { ValF $self }

1;
