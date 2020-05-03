package xcl::script;

use XCL::Builtins::Builder qw(_nonbuiltin_names_of _builtins_of);
use XCL::Class 'XCL::Inline';

sub setup_scope ($self) {
  my $scope = $self->scope->but(intro_as => \&Val);
  $scope->await::set(say => Native->from_foreign(sub { STDOUT->say($_[0]) }));
  $scope->await::set(log => Native->from_foreign(sub { STDERR->say($_[0]) }));
  $scope->await::set(perl_module => Native->from_foreign(sub {
    load_class $_[0];
    PerlObject->from_perl($_[0]);
  }));
  $scope->await::set(exit => Native->from_foreign(sub { exit($_[0]//0) }));
  if (my $pkg = $self->package) {
    foreach my $name (grep /^[A-Za-z]/, _nonbuiltin_names_of $pkg) {
      my $native = Native->from_foreign($pkg->can($name));
      $scope->await::set($name => $native);
    }
    my $pkg_builtins = _builtins_of $pkg;
    $scope->await::set($_ => $pkg_builtins->{$_})
      for sort keys %$pkg_builtins;
  }
  return $self;
};

1;
