use XCL::Weaver;
use XCL::Class -test;

my $w = XCL::Weaver->new;

sub xw ($str) { $w->parse(stmt_list => $str) }

is(
  xw('f(1)'),
  Block [ Compound([ Name('f'), List([ Int(1) ]) ]) ]
);

is(
  xw('f(1) x'),
  Block [ Call [ Compound([ Name('f'), List([ Int(1) ]) ]), Name('x') ] ]
);

is(xw('x + 1'), Block [ Call [ Name('x'), Name('+'), Int(1) ] ]);

$w->ops({ '+' => [ -4, -1 ] });

is(xw('x + 1'), xw('+ x 1'));

is(xw('x y + z'), xw('+ [ x y ] z'));

is(xw('x + y + z'), xw('+ [ + x y ] z'));

is(xw('x()+y'), xw('+ x() y'));

$w->ops({ '.' => [ 3, 0 ] });

is(xw('a b . c d'), xw('a [ . b c ] d'));

is(xw('a.b c'), xw('[ . a b ] c'));

is(xw('x.y.z'), xw('. [ . x y ] z'));

is(xw('x.y.z()'), xw('[ . [ . x y ] z ]()'));

is(xw('x.y.z(1)'), xw('[ . [ . x y ] z ](1)'));

$w->ops({ '+' => [ -4, -1 ], '=' => [ -20, 0 ] });

is(xw('x = y = z + 3'), xw('= x [ = y [ + z 3 ] ]'));

$w->ops({ 'if' => [ -73, 0, 1 ] });

is(xw('x if y'), xw('if y x'));

$w->ops({ '.' => [ 10 ] });

done_testing;
