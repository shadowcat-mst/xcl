package xcl::script;

use Mojo::Util qw(monkey_patch);
use Async::Methods;
use Package::Stash;
use Filter::Util::Call;
use XCL::Values;
use XCL::Builtins;
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
    my $native = Native->from_foreign($subs->{$name});
    $scope->set($name => Val($native));
  }
}

sub run ($class, $targ, $script) {
  my $scope = XCL::Builtins->builtins;
  $class->_coopt($targ, $scope);
  my $res = $scope->await::eval_string($script);
  die $res->err->display(8) unless $res->is_ok;
  return;
}

1;
