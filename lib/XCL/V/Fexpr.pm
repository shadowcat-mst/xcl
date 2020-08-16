package XCL::V::Fexpr;

use XCL::Class 'XCL::V';

async sub invoke_against ($self, $outer_scope, $vals) {
  my ($argspec, $scope, $body) = @{$self->data}{qw(argspec scope body)};
  my $val_res = await $self->_argument_values($outer_scope, $vals);
  return $_ for not_ok $val_res;
  my $iscope = $scope->snapshot;
  return $_ for not_ok +await $iscope->but_intro_as(\&Val,
    $iscope->curry::invoke_method_of(
      Escape($argspec), assign => List[$val_res->val]
    )
  );
  await $iscope->combine($body, List[]);
}

sub _argument_values ($self, $outer_scope, $vals) {
  ValF(List[$outer_scope, $vals->values]);
}

sub display_data ($self, $) {
  return 'fexpr '.$self->data->{argspec}->display(3).' { ... }';
}

async sub c_fx_make ($class, $scope, $lst) {
  my ($argspec_p, $body_proto) = $lst->values;
  my $res = await $scope->eval_concat($body_proto);
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
  ValF Curry([ $self, map $_->values, $lst->values ]);
}

1;
