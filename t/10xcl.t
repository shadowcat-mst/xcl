use xcl::test;

ok true 'True';
ok !false 'False';

todo 'This is meant to fail' {
  ok false 'False';
}

is [ 1 + 2 ] 3 'Basic arithmetic';

{
  let t = + ++ (3);
  is [ t ++ (4) ](5, 6) 18 'Concat-as-curry';
}

{
  var res = ();

  let say = v => {
    res = res ++ (v);
  }

  {
    let foo = %();

    foo('x') = 1;

    let list = (foo, foo);

    list | .'x' | say;
  }

  is res (1, 1) 'Hello world example';
}

{
  let dismantle = fexpr (s, v) {
    let l = v.list();
    %(: type l.0, : of l(1)(0))
  }

  is dismantle(ArrayRef(Str)) %(:type(\ArrayRef), :of(\Str)) 'fexpr';
}

{
  let lst = (2, 3, 4);
  is (1, @lst, 5, 6) 1..6 '@ prefix inside list';
}

{
  let lst = (('c', 3), ('b', 2));
  is %(:d 4, @lst, :a 1) %(:a(1), :b(2), :c(3), :d(4))
    '@ prefix inside dict constructor';
}

{
  let lst = (1, 2, 3, 4);
  is [ + @lst ] 10 '@ prefix flattens list into args';
}

{
  let lst = ((x, y) => { x + y }, 2, 6);
  is [ @lst ] 8 '@ prefix in call';
}

{
  let sum = lst => { + 0 @lst }
  let lst = (1, 2, 3, 4);
  is sum(lst) 10 '@ prefix inside function test';
}

{
  var x = 3;
  assign x 7;
  is x 7 'assign method';
}

{
  let z = 12;
  is z 12 'let';
}

{
  var x = 3;
  x = 1 + 3;
  is x 4 'assign';
}

{
  let bloop = %();
  bloop('x') = 6;
  is bloop %(:x 6) 'dict assign';
}

{
  let (x, y) = (1, 2);
  is (y, x) (2, 1) 'destructure list';
}

is [ \ bar('x')(3) ].to_call() \([ [ bar 'x' ] 3 ]) 'Compound.to_call()';

{
  let (x, var y, z) = (1, 2, 3);
  y = 4;
  is (z, y, x) (3, 4, 1) 'destructure with var';

  let (a, cur y) = (7, 8);
  is (y, a) (8, 7) 'destructure with cur';
}

{
  let ($, $, @foo) = (1, 2, 3, 4);
  is foo (3, 4) 'destructure with rest param';
}

{
  let (x, yval) = (1, 2);
  let d = %(:x, :y yval);
  is d %(:x 1, :y 2) 'dict assembly';
}

{
  let x = 1;
  let splat = (:y 2, :z 3);
  let d = %(:x, @splat);
  is d %(:x 1, :y 2, :z 3) 'dict assembly w/list splat';
}

{
  let x = 1;
  let splat = %(:y 2, :z 3);
  let d = %(:x, @splat);
  is d %(:x 1, :y 2, :z 3) 'dict assembly w/dict splat';
}


diag ^(%);

{
  let d = %(:x 1);
  let %(:x) = d;
  is x 1 'single pair dict destructure';
}
