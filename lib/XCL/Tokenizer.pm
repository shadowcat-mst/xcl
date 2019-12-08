package XCL::Tokenizer;

use strict;
use warnings;

our $SYMBOL_CHARS = '.!$%&*+-/:<=>@\\^_|~';

our @TOKEN_TYPES = (do {
  my @s = (
    [ ws => '\s' => '(\s+)' ],
    [ word => '[a-zA-Z]' => '(\w+)' ],
    [ number => '[0-9]', "([0-9]+(?:\\.[0-9]+)?)" ],
    [ symbol => "[\Q${SYMBOL_CHARS}\E]", "([\Q${SYMBOL_CHARS}\E]+)" ],
    [ string => "'", q{'((?:[^'\\\\]+|\\\\.)*)'} ],
    [ comma => ',' ],
    [ semicolon => ';' ],
    [ start_call => "\\[" ],
    [ end_call => "\\]" ],
    [ start_list => "\\(" ],
    [ end_list => "\\)" ],
    [ start_block => "\\{" ],
    [ end_block => "\\}" ],
    [ comment => '#' => '#.*?(\n|\z)' ],
  );
  $s[$_][2] ||= '('.$s[$_][1].')' for 0..$#s;
  @s;
});

sub extract_next {
  my ($self, $src) = @_;
  return () unless defined($src) and length($src);
  foreach my $type (@TOKEN_TYPES) {
    my ($name, $identify, $slurp) = @$type;
    if ($src =~ /\A${identify}/sm) {
      $src =~ s/\A${slurp}//sm or die "WHAT";
      return ($name => $1, $src);
    }
  }
  die "no idea wtf happened here, blame mst";
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
