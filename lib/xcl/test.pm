package xcl::test;

use XCL::Builtins::Test;
use XCL::Builtins::Builder qw(_builtins_of);
use XCL::Class 'XCL::Inline';

sub setup_scope ($self) {
  my $test_builtins = _builtins_of 'XCL::Builtins::Test';
  dynamically $Am_Running = [
    Name('EXTERNAL'), String(__FILE__), Int(__LINE__)
  ];
  $self->scope->but_intro_as(\&Val, sub {
    $self->scope->await::set($_ => $test_builtins->{$_})
      for sort keys %$test_builtins;
  });
  return $self;
}

after run => sub ($self) {
  XCL::Builtins::Test::done_testing();
};

1;
