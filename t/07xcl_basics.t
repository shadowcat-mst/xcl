use XCL::Class -test;
use XCL::Values;
use XCL::Builtins;

my $scope = XCL::Builtins->builtins;

sub xcl_is ($xcl, $expect, $name = "xcl: $xcl -> $expect") {
  my $res = $scope->await::eval_string($xcl);
  if ($res->is_ok) {
    is($res->val->display(-1), $expect, $name);
  } else {
    fail("${name} returned error: ".$res->err->display(8));
  }
}

xcl_is '3 + 4', '7';

xcl_is '+ [ + 5 6 ] 4', '15';

xcl_is 'let x = 4', '4';

xcl_is 'let x = 3; + x 4', '7';

xcl_is 'assign [let x] 3; $x', '3';

xcl_is 'let x = \[ + 3 ]; x 4', '7';

xcl_is 'let x = \[ + 3 ]; x(4)', '7';

xcl_is 'let x = lambda (x) { + x 3 }; x 4', '7';

xcl_is 'let x = x => { x + 3 }; x(4)', '7';

xcl_is '(1, 2, 3) ++ (4, 5, 6)', '(1, 2, 3, 4, 5, 6)';

xcl_is '.concat() (1, 2) (3, 4)', '(1, 2, 3, 4)';

xcl_is 'let x = \[ + 3 ]; let y = x ++ (4); y 5', '12';

xcl_is '[ + ++ (3, 4) ] 5', '12';

xcl_is '[ .concat() \[+] (3, 4) ](5)', '12';

xcl_is '[ \[+] . concat (3, 4) ] 5', '12';

xcl_is '2 * 3', '6';

xcl_is 'let double = * ++ (2); double(3)', '6';

xcl_is 'var x = 3; x = 5; $x', '5';

xcl_is '(1, 2, 3).map x => { x + 1 }', '(2, 3, 4)';

xcl_is 'let l = (1, 2, 3); l.map x => { x + 1 }', '(2, 3, 4)';

xcl_is 'let b = { x + 1 }; let l = (1, 2, 3); l.map x => b', '(2, 3, 4)';

xcl_is '(1, 2, 3).map \[ + 1 ]', '(2, 3, 4)';

xcl_is q!
  let identity = fexpr (s, v) { s.eval v }
  let x = 'foo';
  identity x
!, "'foo'";

xcl_is '
  let map = (b, l) => { l.map _ => b }
  map { $(_) + 1 } (1, 2, 3)
', '(2, 3, 4)';

xcl_is '[ 0 ]', '0'; # should this even work?

xcl_is '
  let map = (b, l) => {
    let f = (_) => b;
    l.map x => { f(x) }
  }
  map { $_ + 1 } (1, 2, 3)
', '(2, 3, 4)';

xcl_is '
  $ { { 3 } }
  7
', '7';

xcl_is '(1, 2).map(x => { x + 1 })',
  '(2, 3)';

xcl_is '(1, 2).map(x => { x + 1 }).map(x => { x + 2 })',
  '(4, 5)';

xcl_is '(1, 2, 3).1', '2';

xcl_is q{%(('foo', 1), ('bar', 2)).'foo'}, '1';

done_testing;
