package xcl::script;

use XCL::Builtins::Builder qw(_nonbuiltin_names_of _builtins_of);
use XCL::Class 'XCL::Inline';

before run => sub ($self) {
  my $scope = $self->scope;
  $scope->set(say => Val(Native->from_foreign(sub { STDOUT->say($_[0]) })));
  $scope->set(log => Val(Native->from_foreign(sub { STDERR->say($_[0]) })));
  $scope->set(perl_module => Val(Native->from_foreign(sub {
    load_class $_[0];
    PerlObject->from_perl($_[0]);
  })));
  my $pkg = $self->package;
  foreach my $name (grep /^[a-z]/, _nonbuiltin_names_of $pkg) {
    my $native = Native->from_foreign($pkg->can($name));
    $scope->set($name => Val($native));
  }
  my $pkg_builtins = _builtins_of $pkg;
  $scope->await::set($_ => Val $pkg_builtins->{$_})
    for sort keys %$pkg_builtins;
};

1;
