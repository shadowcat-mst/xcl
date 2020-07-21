use xcl::test;

let(unless) = fexpr (scope, cond, block) {
  ?: scope.eval(cond) false [do { scope.call block; true }];
}

{
  var x = 0;
  unless 0 { x = 3 }
  is x 3 'False unless';
}

{
  var x = 0;
  unless 1 { x = 3 }
  is x 0 'True unless';
}

{
  var x = 0;
  unless [ 2 > 1 ] { x = 3 }
  is x 0 'Call unless';
}

{
  let y = 2;
  var r = 0;
  unless [ [ let x = y ] > 4 ] { r = x + 1 }
  is r 3 'let if';
  is x 2 'x set via unless cond';
}
