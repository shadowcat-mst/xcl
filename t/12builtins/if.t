use xcl::test;

let(if) = fexpr (scope, cond, block) {
  let dscope = do scope.derive;
  ?: dscope.eval(cond) [do { dscope.call block; true }] false;
}

{
  var x = 0;
  if 0 { x = 3 }
  is x 0 'False if';
}

{
  var x = 0;
  if 1 { x = 3 }
  is x 3 'True if';
}

{
  var x = 0;
  if [ 2 > 1 ] { x = 3 }
  is x 3 'Call if';
}

{
  let y = 2;
  var r = 0;
  if [ [ let x = y ] > 1 ] { r = x + 1 }
  is r 3 'let if';
  is maybe(x) () 'x does not escape';
}
