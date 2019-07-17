package XCL::Parser;

use Mu;
use strictures 2;
use experimental qw(signatures);

our $SYMBOL_CHARS = q{!#$%&*+-./:<=>@\^_`|~};

our %START_CHARACTER_MAP = (
  word => 'a-zA-Z',
  symbol => $SYMBOL_CHARS,
  number => '0-9',
  statement => '[',
);

sub parse_statement ($self, $) {
  my @stmt;
  for ($_[1]) {
    while (!/\G\Z/gc) {
      /\G\s+/gc;
      if (/\G\]/gc) { return ::Call(\@stmt) } ## HACK
      foreach my $poss (sort keys %START_CHARACTER_MAP) {
        if (/\G[${\quotemeta $START_CHARACTER_MAP{$poss}}]/gc) {
          return $self->${\"parse_${poss}"}($_[1]);
        }
      }
      die "Eh?\n";
    }
  }
  return ::Call(\@stmt);
}

sub _expect ($self, $match, $name, $call, $str) {
  if (my ($m) = $_[4] =~ /\G(${match})/gc) {
    return $call->($m);
  }
  die "Can't parse ${name} from ${str}";
}
  
sub parse_word { $_[0]->_expect('\w+', 'word', \&::Name, $_[1]) }
sub parse_symbol {
   $_[0]->_expect("[${SYMBOL_CHARS}]", 'symbol', \&::Name, $_[1])
}
sub parse_number { $_[0]->_expect('[0-9]+', 'number', \&::Int, $_[1]) }

1;
