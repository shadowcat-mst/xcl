use XCL::Class -test;
use XCL::Values;
use XCL::Builtins;
use XCL::Weaver;

my $w = XCL::Weaver->new(ops => XCL::Builtins->ops);

my $scope = XCL::Builtins->builtins;

sub xcl_is ($xcl, $expect, $name = "xcl: $xcl -> $expect") {
  my $t = $w->parse(stmt_list => $xcl);
  my $val = (my $res = $t->invoke($scope, List[])->get)->val;
  die $res->err->display(-1) unless $res->is_ok;
  is($val->display(-1), $expect, $name);
}

xcl_is '3 + 4', '7';

xcl_is '+ [ + 5 6 ] 4', '15';

xcl_is 'let x = 4', '4';

xcl_is 'let x = 3; + x 4', '7';

xcl_is 'set [let x] 3; $x', '3';

xcl_is 'let x = \[ + 3 ]; x 4', '7';

xcl_is 'let x = ?: 0 3 4; $x', '4';

xcl_is 'let x = \[ + 3 ]; x(4)', '7';

xcl_is 'let x = lambda (x) { + x 3 }; x 4', '7';

xcl_is 'let x = x => { x + 3 }; x(4)', '7';

xcl_is '(1, 2, 3) ++ (4, 5, 6)', '(1, 2, 3, 4, 5, 6)';

xcl_is '.concat (1, 2) (3, 4)', '(1, 2, 3, 4)';

xcl_is 'let x = \[ + 3 ]; let y = x ++ (4); y 5', '12';

xcl_is '[ + ++ (3, 4) ] 5', '12';

xcl_is '[ .concat \[+] (3, 4) ](5)', '12';

xcl_is '[ \[+] . concat (3, 4) ] 5', '12';

xcl_is '2 * 3', '6';

xcl_is 'let double = * ++ (2); double(3)', '6';

xcl_is 'var x = 3; x = 5; $x', '5';

xcl_is '?: 1 0', '1';

xcl_is '?: 0 3', '3';

xcl_is '?: 1 2 3', '2';

xcl_is '?: 0 2 3', '3';

xcl_is '(1, 2, 3).map x => { x + 1 }', '(2, 3, 4)';

xcl_is '(1, 2, 3).map \[ + 1 ]', '(2, 3, 4)';

done_testing;
