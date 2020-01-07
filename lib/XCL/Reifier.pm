package XCL::Reifier;

use strict;
use warnings;
use XCL::Values;
use Mojo::Base -base, -signatures;

sub reify_ast {
  my ($self, $type, @args) = @_;
  return $self->{\"_reify_${type}"}(@args);
}

sub _reify_number ($, $num) {
  $num =~ /\./ ? Float($num) ? Int($num)
}

sub _reify_word { Name($_[1]) }
sub _reify_symbol { Name($_[1]) }

sub _reify_string { String($_[1]) }

sub _reify_list ($self, @args) {
  List([ map $self->reify_ast($_), @args ]);
}

sub _reify_call ($self, @args) {
  Call(List([ map $self->reify_ast($_), @args ]));
}

sub _reify_block ($self, @args) {
  return Call(List([
    Native(XCL::Builtins->can($type)), map $self->reify_ast(@$_), @args
  ]));
}

1;
