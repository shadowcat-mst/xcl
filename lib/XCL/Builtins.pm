package XCL::Builtins;

use XCL::V::Scope;
use XCL::Values;
use Mojo::Base -base, -signatures, -async;

async sub c_fx_set {
  my ($class, $scope, $lst) = @_;
  my ($set, $valproto) = $lst->values;
  my $pres = await $scope->eval($set);
  return $pres unless $pres->is_ok;
  my $place = $pres->val;
  return Err([ Name('NOT_SETTABLE') => String('FIXME') ])
    unless $place->can_set;
  my $valres = await $scope->eval($valproto);
  return $valres unless $valres->is_ok;
  return $place->set($valres->val);
}

sub c_fx_id ($class, $scope, $lst) {
  my @values = $lst->values;
  return ResultF $scope->eval($values[0]) if @values == 1;
  return ResultF $scope->eval(Call(\@values));
}

sub c_fx_escape ($class, $scope, $lst) { ValF $lst->data->[0] }

sub c_fx_result_of ($class, $scope, $lst) {
   ValF $class->c_fx_id($scope, $lst)->get;
}

async sub c_fx_if {
  my ($class, $scope, $lst) = @_;
  my ($cond, $true, $false) = @{$lst->data};
  my $dscope = $scope->derive;
  my $res = await $dscope->eval($cond);
  return $res unless $res->is_ok;
  my $bool = $res->val->bool;
  return $bool unless $bool->is_ok;
  if ($bool->val->data) {
    my $res = await $true->invoke($dscope);
    return defined($false) ? $res : Val($res);
  }
  return await $false->invoke($dscope) if $false;
  return Val(Err([ Name('NO_SUCH_VALUE') => String('else') ]));
}

async sub c_fx_while {
  my ($class, $scope, $lst) = @_;
  my ($cond, $body) = $lst->values;
  my $dscope = $scope->derive;
  my $did;
  WHILE: while (1) {
    my $res = await $dscope->eval($cond);
    return $res unless $res->is_ok;
    my $bool = $res->val->bool;
    return $bool unless $bool->is_ok;
    if ($bool->val->data) {
      $did ||= 1;
      my $bscope = $dscope->derive;
      my $res = await $body->invoke($bscope);
      return $res unless $res->is_ok;
    } else {
      last WHILE;
    }
  }
  return Val(Bool($did));
}

sub c_fx_do ($class, $scope, $lst) {
  $scope->val(Call([ $lst->values ]));
}

async sub c_fx_dot {
  my ($class, $scope, $lst) = @_;
  my ($lp, $rp) = $lst->values;
  my $lr = await $scope->($lp);
  return $lr unless $lr->is_ok;
  my $method_name = String do {
    if ($rp->is('Name')) {
      $rp->data;
    } else {
      my $res = await $scope->eval($rp);
      return $res unless $res->is_ok;
      return Err([ Name('WRONG_TYPE') ]) unless $res->val->is('String');
      $res->val->data;
    }
  };
  my $l = $lr->val;
  my $res;
  # let meta = metadata(l);
  # if [exists let dm = meta('dot_methods')] {
  #   if [exists let m = dm(r)] {
  #     m ++ (l)
  #   } {
  #     meta('dot_via')(r) ++ (l);
  #   }
  # } {
  #   if [exists let dv = meta('dot_via')] {
  #     dv(r) ++ (l);
  #   } {
  #     let sym = Name.make l.type();
  #     let m = scope.eval(sym) r;
  #     m ++ (l);
  #   }
  # }
  if (my $methods = $l->metadata->{dot_methods}) {
    $res = await $methods->invoke($scope, $method_name);
    if (!$res->is_ok and $res->err->data->[0]->data ne 'NO_SUCH_VALUE') {
      return $res;
    }
  }
  unless ($res and $res->is_ok) {
    # only fall back to the object type by default in absence of dot_methods
    if (my $dot_via = $l->metadata->{dot_via} || ($res and Name($l->type))) {
      $res = await $scope->eval(Call([
        Name('.'), $dot_via, $method_name
      ]));
      return $res unless $res->is_ok;
    }
  }
  return Val Call [ $res->val, $l ];
}

sub c_f_metadata ($class, $lst) {
  Dict($lst->[0]->metadata);
}

1;
