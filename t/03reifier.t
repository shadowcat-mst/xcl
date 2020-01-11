use Test2::V0;
use lib 'lib';
use XCL::Values;
use XCL::Reifier;

use Devel::DDCWarn;

is(
  XCL::Reifier->new->parse('stmt_list', 'f(1)'),
  Block [ Compound([ Name('f'), List([ Int(1) ]) ]) ]
);

is(
  XCL::Reifier->new->parse('stmt_list', 'f(1) x'),
  Block [ Call [ Compound([ Name('f'), List([ Int(1) ]) ]), Name('x') ] ]
);

done_testing;
