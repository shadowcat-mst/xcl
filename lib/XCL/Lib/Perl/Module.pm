package XCL::Lib::Perl::Module;

use Symbol ();
use XCL::Builtins::Builder qw(_sub_names_of);
use XCL::Class 'XCL::V';

sub f_name ($self, $) {
  ValF String $self->data;
}

sub f_sub ($self, $lst) {
  my ($sub) = $lst->values;
  my $sub_name = $sub->must_be('String')->data;
  my $code = $self->data->can($sub_name);
  return ErrF([ Name('NO_SUCH_VALUE') => $sub ]) unless $code;
  return ValF(Native->from_foreign($code));
}

async sub fx_call_sub ($self, $scope, $lst_p) {
  return $_ for not_ok my $lres = await $scope->eval($lst_p);
  my ($sub, $args) = $lres->val->ht;
  return $_ for not_ok my $sres = await $self->f_sub(List[$sub]);
  return await $sres->val->invoke($scope, $args);
}

sub fx_call_method ($self, $scope, $lst_p) {
  my ($sub, @args) = $lst_p->values;
  $self->call_sub($scope, List[String($self->data), @args]);
}

async sub fx_import ($self, $scope, $lst_p) {
  state $pkg_stub = 'A0001';
  return $_ for not_ok my $lres = await $scope->eval($lst_p);
  my $scratch_pkg = __PACKAGE__.'::_Scratch_::'.($pkg_stub++);
  $self->data->import::into($scratch_pkg, @{$lres->val->to_perl});
  foreach my $name (_sub_names_of $scratch_pkg) {
    await $scope->set(
      $name => Val Native->from_foreign($scratch_pkg->can($name))
    )
  }
  Symbol::delete_package $scratch_pkg;
  return Val True;
}

1;
