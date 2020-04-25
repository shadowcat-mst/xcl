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
