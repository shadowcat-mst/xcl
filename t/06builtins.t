use XCL::Builtins;
use XCL::Class -test;

my $raw;

bail_out unless try_ok { XCL::Builtins->ops };
bail_out unless try_ok { $raw = XCL::Builtins->builtins };

use XCL::Builtins::Builder qw(
  _builtin_names_of _builtins_of
  _value_type_builtins
);
use XCL::V;

is [ map $_->[3], _builtin_names_of 'XCL::V' ], [ qw(and or) ];

my $builtins = Scope Dict $raw;

my $plus = $builtins->get('+')->get->val;

is $plus->invoke($builtins, List [ Int(3), Int(4) ])->get, Val(Int 7);

is $plus->invoke($builtins, List [ Float(3), Float(4) ])->get, Val(Float 7);

done_testing;
