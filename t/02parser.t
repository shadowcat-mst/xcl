use strict;
use warnings;
use lib 'lib';
use Test2::V0;
use experimental 'signatures';
use feature 'state';
use XCL::Parser;

sub xp ($x) {
  state $p =  XCL::Parser->new;
  my $parse = $p->parse(stmt_list => $x);
  #return ::Dwarn $parse;
  return $parse;
}

is xp('x(1)'), [
  'block', [
    'stmt',
    [ 'compound', [ 'word', 'x' ], [ 'list', [ 'expr', [ 'number', 1 ] ] ] ],
  ],
];

is xp("x { y z }\nn"), [ block =>
  [ stmt =>
    [ word => 'x' ],
    [ block => [ stmt => [ word => 'y' ], [ word => 'z' ] ] ],
  ],
  [ stmt =>
    [ word => 'n' ]
  ]
];

done_testing;
