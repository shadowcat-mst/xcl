package XCL::V::Fexpr;

use XCL::Class 'XCL::V';

sub _invoke ($self, $outer_scope, $vals) {
  my ($argnames, $scope, $body) = @{$self->data}{qw(argnames scope body)};
  my %merge; @merge{@$argnames} = map Val($_), $outer_scope, $vals->values;
  $body->invoke($scope->derive(\%merge), List []);
}

sub display_data ($self, $) {
  return 'fexpr ('.join(', ', @{$self->data->{argnames}}).') { ... }';
}

async sub c_fx_make {
  my ($class, $scope, $lst) = @_;
  my ($argspec, $body_proto) = $lst->values;
  my $res = await $body_proto->evaluate_against($scope);
  return $res unless $res->is_ok;
  my @argnames = map $_->data, $argspec->values;
  Val($class->new(data => {
    argnames => \@argnames,
    scope => $scope,
    body => $res->val,
  }, metadata => {}));
}

sub f_concat ($self, $lst) {
  return $_ for $self->_same_types($lst, 'List');
  ValF Call([ $self, map $_->values, $lst->values ]);
}

1;
