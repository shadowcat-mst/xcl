use Test2::V0;
use Mojo::Base -strict, -signatures;
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

is xp('+ [ x y ] z'), [
  'block', [
    'stmt', [ 'symbol', '+' ], [ 'call', [ 'word', 'x' ], [ 'word', 'y' ] ],
    [ 'word', 'z' ],
  ],
];

is xp('x()'),
  [ 'block', [ 'stmt', [ 'compound', [ 'word', 'x' ], [ 'list' ] ] ] ];

done_testing;
