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

is(
  xr('
    $ { { 3 } }
    7
  '), # ->tap(sub ($x) { warn $x->data->[0]->display(-1) }),
  Block [
    Call([ Name('$'), Block [ Call [ Block [ Call [ Int(3) ] ] ] ] ]),
    Call [ Int(7) ],
  ]
);

done_testing;
