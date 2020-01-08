package XCL::V::Fexpr;

use XCL::Values;
use Mojo::Base 'XCL::V', -signatures, -async;

sub invoke ($self, $outer_scope, $vals) {
  my ($argnames, $scope, $body) = @{$self->data}{qw(argnames scope body)};
  my %merge; @merge{@$argnames} = map Val($_), $outer_scope, $vals->values;
  $body->evaluate_against($scope->derive(\%merge));
}

sub display ($self, @) {
  return 'fexpr ('.join(', ', @{$self->data->{argnames}}).') { ... }';
}

async sub c_fx_make {
  my ($class, $scope, $lst) = @_;
  my ($argspec, $body_proto) = $lst->values;
  my $res = await $body_proto->eval_against($scope);
  return $res unless $res->is_ok;
  my @argnames = map $_->data, $argspec->values;
  Val($class->new(
    argnames => \@argnames,
    scope => $scope,
    body => $res->val,
  ));
}

1;
