use strict;
use warnings;
use lib 'lib';
use Test2::V0;
use experimental 'signatures';
use feature 'state';
use XCL::Parser;

sub xp (@x) {
  state $p =  XCL::Parser->new;
  my ($toks, $block) = $p->extract_stmt_list(@x);
  is $toks, [];
  #return ::Dwarn $block;
  return $block;
}

is xp(
  [ word => 'x' ],
  [ start_list => '(' ],
  [ number => '1' ],
  [ end_list => ')' ],
), [
  'block', [
    'stmt',
    [ 'compound', [ 'word', 'x' ], [ 'list', [ 'call', [ 'number', 1 ] ] ] ],
  ],
];

is xp(
  [ word => 'x' ],
  [ ws => ' ' ],
  [ start_block => '{' ],
  [ word => 'y' ],
  [ ws => ' ' ],
  [ word => 'z' ],
  [ end_block => '}' ],
  [ ws => "\n" ],
  [ word => 'n' ],
), [ block =>
  [ stmt =>
    [ word => 'x' ],
    [ block => [ stmt => [ word => 'y' ], [ word => 'z' ] ] ],
  ],
  [ stmt =>
    [ word => 'n' ]
  ]
];

done_testing;
