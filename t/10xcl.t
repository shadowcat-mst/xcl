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

  let say = v => { res = res ++ (v) };

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
  assign [ alet z ] 12;
  is z 12 'alet';
}
