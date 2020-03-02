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

is xp('{ 3 };'),
  [ 'block', [ 'stmt', [ 'block', [ 'stmt', [ 'number', 3 ] ] ] ] ];

# < mst> ffft
# < mst> given a nested block like { { 3 } } the parser is somehow only 
#        jumping out one level to begin with when it hits the } } so the 
#        next token is interpreted as being *inside* the outer block
# < mst> as if you'd written { { 3 }; 7 } not { { 3 } }; 7

# Bad output looks like: [
#   'block', [
#     'stmt', [
#       'block', [ 'stmt', [ 'block', [ 'stmt', [ 'number', 3 ] ] ] ],
#       [ 'stmt', [ 'number', 7 ] ],
#     ],
#   ],
# ]

is xp('
  { { 3 } }
  7
'), [
  'block', [
    'stmt', [
      'block', [ 'stmt', [ 'block', [ 'stmt', [ 'number', 3 ] ] ] ],
    ],
  ],
  [ 'stmt', [ 'number', 7 ] ],
];

done_testing;
