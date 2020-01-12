use Test2::V0;
use Mojo::Base -strict, -signatures;
use XCL::Values;
use XCL::Weaver;

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

$w->ops({ '+' => -4 });

is(xw('x + 1'), xw('+ x 1'));

is(xw('x y + z'), xw('+ [ x y ] z'));

is(xw('x + y + z'), xw('+ [ + x y ] z'));

is(xw('x()+y'), xw('+ x() y'));

$w->ops({ '.' => 3 });

is(xw('a b . c d'), xw('a [ . b c ] d'));

is(xw('a.b c'), xw('[ . a b ] c'));

is(xw('x.y.z'), xw('. [ . x y ] z'));

is(xw('x.y.z()'), xw('[ . [ . x y ] z ]()'));

is(xw('x.y.z(1)'), xw('[ . [ . x y ] z ](1)'));

done_testing;
