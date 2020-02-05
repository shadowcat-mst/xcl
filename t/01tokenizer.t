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

done_testing;
