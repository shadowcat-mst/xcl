package XCL::Reifier;

use XCL::Class;

has parser => sub {
  require XCL::Parser;
  XCL::Parser->new
};

sub parse ($self, $type, $str) {
  my $parse = $self->parser->parse($type, $str);
  $self->reify_ast(@$parse);
}

sub reify_ast ($self, $type, @args) {
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
  List([ map $self->reify_ast(@$_), @args ]);
}

sub _reify_call ($self, @args) {
  Call([ map $self->reify_ast(@$_), @args ]);
}

sub _reify_expr ($self, @args) {
  @args == 1
    ? $self->reify_ast(@{$args[0]})
    : $self->_reify_call(@args);
}

sub _reify_stmt ($self, @args) {
  @args == 1 && (grep { $_ eq 'compound' or $_ eq 'list' } $args[0][0])
    ? $self->reify_ast(@{$args[0]})
    : $self->_reify_call(@args);
}

sub _reify_block ($self, @args) {
  Block([ map $self->reify_ast(@$_), @args ])
}

sub _reify_compound ($self, @args) {
  Compound([ map $self->reify_ast(@$_), @args ])
}

1;
