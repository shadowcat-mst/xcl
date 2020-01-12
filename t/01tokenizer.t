use Test2::V0;
use Mojo::Base -strict, -signatures;
use XCL::Tokenizer;

sub tk ($str) { state $tk = XCL::Tokenizer->new; [ $tk->tokenize($str) ] }

is tk('x'), [[ word => 'x' ]];

is tk('x(1)'), [
  [ word => 'x' ],
  [ start_list => '(' ],
  [ number => '1' ],
  [ end_list => ')' ],
];

done_testing;
