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
    %(('type', l.0), ('of', l(1)(0)))
  }

  is dismantle(ArrayRef(Str)) %(('type', \ArrayRef), ('of', \Str)) 'fexpr';
}

{
  let lst = (1, 2, 3, 4);
  is [ + 0 @lst ] 10 '@ prefix flattens list into args';
}
