use XCL::Reifier;
use XCL::Class -test;

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
