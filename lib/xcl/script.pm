package xcl::script;

use Mojo::Util qw(monkey_patch);
use Package::Stash;
use Filter::Util::Call;
use XCL::Values;
use XCL::Builtins;
use XCL::Weaver;
use XCL::Class;

sub import ($class) {
  my $targ = caller;
  filter_add(sub {
    filter_del();
    1 while filter_read();
    my $text = $_;
    monkey_patch $targ, run_xcl_script => $class->curry::run($targ, $text);
    $_ = 'run_xcl_script(); 1;';
    return 1;
  });
}

sub _coopt ($class, $targ, $scope) {
  my $subs = Package::Stash->new($targ)->get_all_symbols('CODE');
  foreach my $name (grep /^[a-z]/, sort keys %$subs) {
    my $native = XCL::V::Native->from_foreign($subs->{$name});
    $scope->set($name => Val($native));
  }
}

sub run ($class, $targ, $text) {
  my $w = XCL::Weaver->new(ops => XCL::Builtins->ops);
  my $scope = XCL::Builtins->builtins;
  $class->_coopt($targ, $scope);
  my $t = $w->parse(stmt_list => $text);
  my $res_f = $t->invoke($scope, List[]);
  if ($res_f->isa('Mojo::Promise')) {
    $res_f = $res_f->with_roles('+Futurify')->futurify;
  }
  my $val = (my $res = $res_f->get)->val;
  die $res->err->display(4) unless $res->is_ok;
  return;
}

1;
