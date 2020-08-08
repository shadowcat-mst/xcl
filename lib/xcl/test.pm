package xcl::test;

use XCL::Builtins::Test;
use XCL::Builtins::Builder qw(_builtins_of);
use XCL::Class 'XCL::Inline';

sub setup_scope ($self) {
  my $test_builtins = _builtins_of 'XCL::Builtins::Test';
  my $scope = $self->scope->but(intro_as => \&Val);
  dynamically $Am_Running = [
    Name('EXTERNAL'), String(__FILE__), Int(__LINE__)
  ];
  $scope->await::set($_ => $test_builtins->{$_})
    for sort keys %$test_builtins;
  $self->scope->data($scope->data);
  return $self;
};

after run => sub ($self) {
  XCL::Builtins::Test::done_testing();
};

1;
