package XCL::V::Lambda;

use XCL::Values;
use Role::Tiny::With;
use Mojo::Base 'XCL::V::Fexpr', -signatures, -async;

async sub invoke {
  my ($self, $outer_scope, $vals) = @_;
  my $argvalres = await $vals->evaluate_against($outer_scope);
  return $argvalres unless $argvalres->is_ok;
  return await $self->SUPER::invoke($outer_scope, $argvalres->val);
}

sub display ($self, @) {
  return 'lambda ('.join(', ', @{$self->data->{argnames}}).') { ... }';
}

1;
