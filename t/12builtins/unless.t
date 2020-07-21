use xcl::test;

{
  var x := 0;
  unless 0 { x := 3 }
  is x 3 'False unless';
}

{
  var x := 0;
  unless 1 { x := 3 }
  is x 0 'True unless';
}

{
  var x := 0;
  unless [ 2 > 1 ] { x := 3 }
  is x 0 'Call unless';
}

{
  let y := 2;
  var r := 0;
  unless [ [ let x := y ] > 4 ] { r := x + 1 }
  is r 3 'let unless';
  is x 2 'x set via unless cond';
}

{
  let y := 2;
  var r := 0;
  r := x + 1 unless [ let x := y ] > 4;
  is r 3 'let unless binop';
  is x 2 'x set via unless binop cond';
}
