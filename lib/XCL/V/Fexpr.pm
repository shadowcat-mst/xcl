package XCL::V::Fexpr;

use XCL::Class 'XCL::V';

async sub _invoke ($self, $outer_scope, $vals) {
  my ($argspec, $scope, $body) = @{$self->data}{qw(argspec scope body)};
  my $val_res = await $self->_invoke_values($outer_scope, $vals);
  return for not_ok $val_res;
  my $iscope = $scope->snapshot;
  return $_ for not_ok +await dot_call_escape(
    $iscope->but(intro_as => \&Val),
    $argspec, assign => $val_res->val
  );
  await $body->invoke($iscope);
}

sub _invoke_values ($self, $outer_scope, $vals) {
  ValF(List[$outer_scope, $vals->values]);
}

sub display_data ($self, $) {
  return 'fexpr '.$self->data->{argspec}->display(3).' { ... }';
}

async sub c_fx_make ($class, $scope, $lst) {
  my ($argspec_p, $body_proto) = $lst->values;
  my $res = await $body_proto->evaluate_against($scope);
  return $res unless $res->is_ok;
  my ($argspec) = map $_->is('List') ? $_ : List([$_]), $argspec_p;
  Val($class->new(data => {
    argspec => $argspec,
    scope => $scope,
    body => $res->val,
  }, metadata => {}));
}

sub f_concat ($self, $lst) {
  return $_ for $self->_same_types($lst, 'List');
  ValF Call([ $self, map $_->values, $lst->values ]);
}

1;
