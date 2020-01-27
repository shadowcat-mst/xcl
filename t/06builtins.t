use XCL::Builtins;
use XCL::Class -test;

bail_out unless try_ok { XCL::Builtins->ops };
bail_out unless try_ok { XCL::Builtins->builtins };

use XCL::Builtins::Builder qw(_builtin_names_of _builtins_of);
use XCL::V;

is [ map $_->[3], _builtin_names_of 'XCL::V' ], [ qw(and or) ];

my $v = Scope(Dict _builtins_of 'XCL::V');

my $and = $v->get('and')->get->val;

is $and->invoke(Scope({}), List[ Int(0), Int(3) ])->get->val, Int(3);

is $and->invoke(Scope({}), List[ Int(1), Int(3) ])->get->val, Int(1);

done_testing;
