package XCL::Tokenizer;

use strict;
use warnings;

our $SYMBOL_CHARS = '.!$%&*+-/:<=>@\\^_|~';

our %LOOKUP = (
  ' ' => 'ws',
  "\t" => 'ws',
  "\n" => 'ws',
  (map +("$_" => 'number'), 0..9),
  (map +($_ => 'word'), ('a' .. 'z'), ('A' .. 'Z'), '_'),
  (map +($_ => 'symbol'), split '', $SYMBOL_CHARS),
  "'" => 'string',
  "," => 'comma',
  ";" => 'semicolon',
  '[' => 'start_call',
  '(' => 'start_list',
  '{' => 'start_block',
  ']' => 'end_call',
  ')' => 'end_list',
  '}' => 'end_block',
  '#' => 'comment',
);

our %TOKEN_REGEXPS = (
  ws => '\s+',
  word => '\w+',
  number => '[0-9]+(?:\\.[0-9]+)?',
  symbol => "[\Q${SYMBOL_CHARS}\E]+",
  string => q{'((?:[^'\\\\]+|\\\\.)*)'},
  comment => q{#(?:.*?\n|({+)(.*?)\1#)},
);

sub extract_next {
  my ($self, $src) = @_;
  return () unless defined($src) and length($src);
  my $type = $LOOKUP{substr($src,0,1)};
  die "no idea wtf happened here, blame mst" unless $type;
  my $re = $TOKEN_REGEXPS{$type}||'.';
  if ($src =~ s/^(${re})//s) {
    my $tok = $1;
    return ($type, $tok, $src);
  }
  # need to complain loudly with lots of information
  die "READ THE COMMENTS";
}

sub tokenize {
  my ($self, $src) = @_;
  my @tok;
  while (my ($type, $tok, $src) = $self->extract_next($self, $src)) {
    push @tok, [ $type, $tok ];
  }
  return @tok;
}

1;
