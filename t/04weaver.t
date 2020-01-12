use Test2::V0;
use Mojo::Base -strict, -signatures;
use XCL::Values;
use XCL::Weaver;

sub xw ($str) { state $r = XCL::Weaver->new; $r->parse(stmt_list => $str) }

is(
  xw('f(1)'),
  Block [ Compound([ Name('f'), List([ Int(1) ]) ]) ]
);

is(
  xw('f(1) x'),
  Block [ Call [ Compound([ Name('f'), List([ Int(1) ]) ]), Name('x') ] ]
);

done_testing;
