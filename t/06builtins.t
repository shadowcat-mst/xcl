use XCL::Builtins;
use XCL::Class -test;

my $builtins;

bail_out unless try_ok { $builtins = XCL::Builtins->builtins };

use XCL::Builtins::Builder qw(
  _builtin_names_of _builtins_of
  _value_type_builtins
);
use XCL::V;

my $plus = $builtins->await::get('+')->val;

is $builtins->await::combine($plus, List [ Int(3), Int(4) ]), Val(Int 7);

is $builtins->await::combine($plus, List [ Float(3), Float(4) ]), Val(Float 7);

my $not = Call [ Name('.'), Name('Bool'), Name('not') ];

is $builtins->await::eval($not)->val, $builtins->await::get('not')->val;

done_testing;
