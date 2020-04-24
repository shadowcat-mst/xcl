package xcl::test;

use XCL::Builtins::Test;
use XCL::Builtins::Builder qw(_builtins_of);
use XCL::Class 'XCL::Inline';

before run => sub ($self) {
  my $test_builtins = _builtins_of 'XCL::Builtins::Test';
  my $scope = $self->scope;
  $scope->await::set($_ => Val $test_builtins->{$_})
    for sort keys %$test_builtins;
};

after run => sub ($self) {
  XCL::Builtins::Test::done_testing();
};

1;
