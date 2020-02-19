use XCL::Class -test;
use XCL::Values;
use XCL::Builtins;
use XCL::Weaver;

my $w = XCL::Weaver->new(ops => XCL::Builtins->ops);

my $scope = XCL::Builtins->builtins;

sub xcl_is ($xcl, $expect, $name = "xcl: $xcl") {
  my $t = $w->parse(stmt_list => $xcl);
  my $res = $t->invoke($scope, List[])->get->val;
  is($res->display(-1), $expect, $name);
}

xcl_is '3 + 4', '7';

done_testing;
