package xcl::script;

use Package::Stash;
use XCL::Class 'XCL::Inline';

before run => sub ($self) {
  my $scope = $self->scope;
  $scope->set(say => Val(Native->from_foreign(sub { STDOUT->say($_[0]) })));
  $scope->set(log => Val(Native->from_foreign(sub { STDERR->say($_[0]) })));
  my $subs = Package::Stash->new($self->package)->get_all_symbols('CODE');
  foreach my $name (grep /^[a-z]/, sort keys %$subs) {
    my $native = Native->from_foreign($subs->{$name});
    $scope->set($name => Val($native));
  }
};

1;
