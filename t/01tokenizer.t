use XCL::Tokenizer;
use XCL::Class -test;

sub tk ($str) { state $tk = XCL::Tokenizer->new; [ $tk->tokenize($str) ] }

is tk('x'), [[ word => 'x' ]];

is tk('x(1)'), [
  [ word => 'x' ],
  [ start_list => '(' ],
  [ number => '1' ],
  [ end_list => ')' ],
];

is tk("'foo'"), [[ string => 'foo' ]];

is tk('{ 3 }'), [
  [ 'start_block', '{' ],
    [ 'ws', ' ' ],
    [ 'number', 3 ],
    [ 'ws', ' ' ],
  [ 'end_block', '}' ],
];

is tk('{ 3 };'), [
  [ 'start_block', '{' ],
    [ 'ws', ' ' ],
    [ 'number', 3 ],
    [ 'ws', ' ' ],
  [ 'end_block', '}' ],
  [ 'semicolon', ';' ],
];

# this test is theoretically pointless but is the exact same xcl source
# as a 02parser test for a subtle bug

is tk('{ { 3 } }; 7'), [
  [ 'start_block', '{' ], [ 'ws', ' ' ], [ 'start_block', '{' ],
  [ 'ws', ' ' ], [ 'number', 3 ], [ 'ws', ' ' ], [ 'end_block', '}' ],
  [ 'ws', ' ' ], [ 'end_block', '}' ], [ 'semicolon', ';' ], [ 'ws', ' ' ],
  [ 'number', 7 ],
];

done_testing;
