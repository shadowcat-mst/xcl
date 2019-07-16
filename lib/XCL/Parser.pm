package XCL::Parser;

use Mu;
use strictures 2;
use experimental qw(signatures);

our $SYMBOL_CHARS = q{!#$%&*+-./:<=>@\^_`|~};

sub parse_statement ($self, $) {
  my @stmt;
  for ($_[1]) {
    while (!/\G\Z/gc) {
      /\G\s+/gc;
      push @stmt, do {
        if (/\G(?=[a-zA-Z_])/gc)            { $self->parse_word($_[1]) }
        elsif (/\G(?=[${SYMBOL_CHARS}])/gc) { $self->parse_symbol($_[1]) }
        elsif (/\G(?=[0-9])/gc)             { $self->parse_number($_[1]) }
        elsif (/\G\[/gc)                    { $self->parse_statement($_[1]) }
        elsif (/\G\]/gc) { return ::Call(\@stmt) } ## HACK
        else { die "Failed to parse: $_[1]\n" }
      };
    }
  }
  return ::Call(\@stmt);
}

sub parse_word ($self, $str) {
  for ($_[1]) {
    if (my ($word) = /\G(\w+)/gc) {
      return ::Name($word);
    }
  }
  die "Can't parse word from ${str}\n";
}

sub parse_symbol ($self, $str) {
  for ($_[1]) {
    if (my ($symbol) = /\G([${SYMBOL_CHARS}]+)/gc) {
      return ::Name($symbol);
    }
  }
  die "Can't parse symbol from ${str}\n";
}

sub parse_number ($self, $str) {
  for ($_[1]) {
    if (my ($int) = /\G([0-9]+)/gc) {
      return ::Int($int);
    }
  }
  die "Can't parse number from ${str}\n";
}

1;
