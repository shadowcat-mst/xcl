use xcl::test;

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
