package XCL::Reifier;

use strict;
use warnings;
use XCL::Values;
use Mojo::Base -base, -signatures;

has parser => sub {
  require XCL::Parser;
  XCL::Parser->new
};

sub parse ($self, $type, $str) {
  my $parse = $self->parser->parse($type, $str);
  $self->reify_ast(@$parse);
}

sub reify_ast {
  my ($self, $type, @args) = @_;
  return $self->${\"_reify_${type}"}(@args);
}

sub _reify_number ($, $num) {
  $num =~ /\./ ? Float($num) : Int($num)
}

sub _reify_word { Name($_[1]) }
sub _reify_symbol { Name($_[1]) }

sub _reify_string { String($_[1]) }
sub _reify_blockstring { String($_[1]) }

sub _reify_list ($self, @args) {
  List([
    map $self->reify_ast(@$_),
      map { $_->[0] eq 'call' && @$_ == 2 ? $_->[1] : $_ }
        @args 
  ]);
}

sub _reify_call ($self, @args) {
  Call([ map $self->reify_ast(@$_), @args ]);
}

sub _reify_block ($self, @args) {
  Block([
    map $self->reify_ast(@$_),
      map {
        $_->[0] eq 'call' && @$_ == 2 && $_->[1][0] eq 'compound'
          ? $_->[1]
          : $_
      } @args 
  ]);
}

sub _reify_compound ($self, @args) {
  Compound([ map $self->reify_ast(@$_), @args ])
}

1;
