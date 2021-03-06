use xcl::test;

ok true 'True';
ok !false 'False';

todo 'This is meant to fail' {
  ok false 'False';
}

is [ 1 + 2 ] 3 'Basic arithmetic (plus)';

is -3 [ 0 - 3 ] 'Basic arithmetic (minus)';

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
    let foo = mut %();

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
  let bloop = mut %();
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

#diag ^(%);

{
  let d = %(:x 1);
  let %(:x) = d;
  is x 1 'single pair dict destructure';
}

{
  let d = %(:x 1);
  let %(:x(y)) = d;
  is y 1 'single pair dict destructure w/name';
}

{
  let d = %(:x 1, :y 2);
  let %(:x, :y(yval)) = d;
  is (x, yval) (1, 2) 'two pair dict destructure';
}

{
  let d = %(:x 1, :y 2, :z 3);
  let %(:x, %rest) = d;
  is x 1 'extract one dict value w/rest';
  is rest %(:y 2, :z 3) 'extract dict rest as dict';
}

{
  let args = (:x 1, :y 2, 'foo', 'bar');
  let (:x, :y, f, b) = args;
  is (x, y, f, b) (1, 2, 'foo', 'bar') 'mixed destructure';
}

{
  var called = 0;
  let f = (%opts, @args) => {
    is opts %(:x 1, :y 2) 'opts in function';
    is args (7, 8, 9) 'args in function';
    called = 1;
  }
  let x = 1;
  f :x :y(2) 7 8 9;
  is called 1 'function called';
}

{
  var called = 0;
  let f = (first, @((%opts, @args))) => {
    is first 3 'initial arg';
    is opts %(:x 1, :y 2) 'opts in function';
    is args (7, 8, 9) 'args in function';
    called = 1;
  }
  let x = 1;
  f 3 :x :y(2) 7 8 9;
  is called 1 'function called';
}

{
  let l = (1, 2);
  let m = matches((1, 2, 3) = l);
  is m false 'match failed';
  let m = matches((1, 2) = l);
  is m true 'match succeeded';
}

is [true == true] true 'bool eq';
is [false == false] true 'bool eq';
is [true == false] false 'bool eq';
is [false == true] false 'bool eq';

{
  let l = (1, 2);
  let m = matches(let (x, y, z) = l);
  is m false 'mismatch on length w/name';
  let m = matches(let (1, 2, ()) = l);
  is m false 'mismatch on length w/list';
  let (x, y, z = 3) = l;
  is (z, y, x) (3, 2, 1) 'list destructure with default';
}

{
  let d = %(:x 1);
  let %(:x, :y(y = 2)) = d;
  is (y, x) (2, 1) 'dict destructure with default';
}

{
  var x = 3;
  is x 3 'assign (sanity check)';
  \x.assign 5;
  is x 5 'assign via method';
}

{
  var f_args = ();
  let f = (:flag1, :flag2(flag2 = false), arg1, arg2 = 0) => {
    f_args = (flag1, flag2, arg1, arg2);
  }
  f :flag1(3) 7;
  is f_args (3, false, 7, 0) 'function args with defaults';
}

{
  let user = %(:nick 'alnk', :name %(:first 'al', :last 'newkirk'));
  let %(:nick, :name(%(:first, %))) = user;
  is (nick, first) ('alnk', 'al') 'deep dict destructure';
}

{
  let d = %(:foo 1);
  is matches(List($) = d) false 'List does not match Dict';
  is matches(Dict($) = d) true 'Dict does match Dict';

  let f = (Dict arg) => {
    is arg d 'Dict arg passed in with type check';
  }

  f(d);
}

{
  let d = mut %();

  d.'foo' = 1;

  is d %(:foo 1) 'dict assign through .';
}
