use Test2::V0;
use lib 'lib';
use Mojo::Base -strict, -signatures;
use XCL::Values;
use XCL::Reifier;

sub xr ($str) { state $r = XCL::Reifier->new; $r->parse(stmt_list => $str) }

is(
  xr('f(1)'),
  Block [ Compound([ Name('f'), List([ Int(1) ]) ]) ]
);

is(
  xr('f(1) x'),
  Block [ Call [ Compound([ Name('f'), List([ Int(1) ]) ]), Name('x') ] ]
);

done_testing;
