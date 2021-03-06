package xcl::script;

use XCL::Builtins::Builder qw(_nonbuiltin_names_of _builtins_of);
use XCL::Lib::Perl;
use XCL::Class 'XCL::Inline';

sub setup_scope ($self) {
  my $scope = $self->scope;
  $scope->but_intro_as(\&Val, sub {
    $scope->await::set(say => Native->from_foreign(sub { STDOUT->say($_[0]) }));
    $scope->await::set(log => Native->from_foreign(sub { STDERR->say($_[0]) }));
    $scope->await::set(exit => Native->from_foreign(sub { exit($_[0]//0) }));
    $scope->await::set(perl => XCL::Lib::Perl->new_with_methods);

    if (my $pkg = $self->package) {
      foreach my $name (grep /^[A-Za-z]/, _nonbuiltin_names_of $pkg) {
        my $native = Native->from_foreign($pkg->can($name));
        $scope->await::set($name => $native);
      }
      my $pkg_builtins = _builtins_of $pkg;
      $scope->await::set($_ => $pkg_builtins->{$_})
        for sort keys %$pkg_builtins;
    }
  });
  return $self;
};

1;
