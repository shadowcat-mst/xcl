package XCL::Lib::Perl;

use XCL::Lib::Perl::Module;
use XCL::Class 'XCL::V';

sub f_module ($self, $lst) {
  my ($name_v) = $lst->values;
  my $name = $name_v->must_be('String')->data;
  load_class $name;
  return ValF(XCL::Lib::Perl::Module->new_with_methods(
    data => $name,
    metadata => {}
  ));
}

sub f_class ($self, $lst) {
  my ($name_v) = $lst->values;
  my $name = $name_v->must_be('String')->data;
  load_class $name;
  return ValF PerlObject->from_perl($name);
}

async sub fx_import ($self, $scope, $lst_p) {
  return $_ for not_ok my $lres = await $scope->eval($lst_p);
  my ($name, $args) = $lres->val->ht;
  return $_ for not_ok my $mres = await $self->f_module(List[$name]);
  return await $mres->val->fx_import($scope, $args);
}

1;
