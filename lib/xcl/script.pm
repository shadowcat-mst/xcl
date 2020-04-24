package xcl::script;

use Package::Stash;
use XCL::Class 'XCL::Inline';

before run => sub ($self) {
  my $scope = $self->scope;
  my $subs = Package::Stash->new($self->package)->get_all_symbols('CODE');
  foreach my $name (grep /^[a-z]/, sort keys %$subs) {
    my $native = Native->from_foreign($subs->{$name});
    $scope->set($name => Val($native));
  }
};

1;
