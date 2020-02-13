use XCL::Parser;
use XCL::Class -test;

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

is xp('{ 3 }'),
  [ 'block', [ 'stmt', [ 'block', [ 'stmt', [ 'number', 3 ] ] ] ] ];

done_testing;
