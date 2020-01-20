package XCL::Builtins::Builder;

use XCL::V::Scope;
use XCL::Builtins::Functions;
use XCL::Class -strict;

sub _construct_builtin ($namespace, $stash_name, $cls_unwrap = 0) {
  my ($is_class, $fexpr, $name) = $stash_name =~ /^((?:c_)?)f(x?)_(.*)/;
  my $sub = $namespace->can($stash_name);
  my $native = do {
    if ($is_class) {
      if ($fexpr) {
        $sub;
      } else {
        async sub {
          my ($scope, $lst) = @_;
          my $res = await $scope->eval($lst);
          return $res unless $res->is_ok;
          $sub->($res->val->values);
        };
      }
    } else {
      if ($fexpr) {
        async sub {
          my ($scope, $lst) = @_;
          my ($obj, @args) = $lst->values;
          my $ores = await $scope->eval($obj);
          return $ores unless $ores->is_ok;
          $sub->($ores->val, @args);
        };
      } else {
        async sub {
          my ($scope, $lst) = @_;
          my $res = await $scope->eval($lst);
          return $res unless $res->is_ok;
          my ($obj, @args) = $res->val->values;
          $sub->($obj, @args);
        };
      }
    }
  };
  return Val Native $native unless $cls_unwrap;
  return Val Native sub ($scope, $lst) {
    # Possibly this should deref the name and include it in the scope?
    my (undef, @args) = $lst->values;
    $native->($scope, @args);
  };
}

sub _builtin_names_of ($namespace) {
  my $file = join('/', split '::', $namespace).'.pm';
  require $file;
  return
    grep $namespace->can($_),
      grep /^(?:c_)?fx?_./,
        sort do { no strict 'refs'; keys %{"${namespace}::"} };
}

sub _builtins_of ($namespace, $unwrap = 0) {
  return +{
    map +(
      $_ =~ /^(?:c_)?fx?_(.+)$/
       => _construct_builtin $namespace, $_, $unwrap
    ), _builtin_names_of $namespace
  };
}

sub _value_builtins () {
  Val Name(
    Value => {
      dot_methods => Dict(_builtins_of 'XCL::V', 'unwrap')
    }
  );
}

sub _value_type_builtins ($vtype) {
  my $vbuiltins = _builtins_of "XCL::V::${vtype}", 'unwrap';
  return Val Name(
    $vtype, { dot_methods => Dict($vbuiltins) }
  );
}

sub _assemble_value ($builtins, $to) {
  my @bits = split /\./, $to;
  if (@bits > 1) {
    return XCL::Builtins::Functions->c_fx_dot(
      Scope($builtins),
      List [ map String($_), grep length, @bits ]
    )->get;
  }
  return $builtins->{$bits[0]};
}

sub _load_builtins (@map) {

  my $builtins = _builtins_of 'XCL::Builtins::Functions';

  $builtins->{Value} = _value_builtins;

  foreach my $vtype (@XCL::Values::Types) {
    my $vbuiltins = _builtins_of "XCL::V::${vtype}", 'unwrap';
    $builtins->{$vtype} = _value_type_builtins $vtype;
  }

  foreach my $thing (grep defined $_->[1][0], @map) {
    my ($alias, $to) = @$thing;
    $builtins->{$alias} = _assemble_value $builtins, $to->[0];
  }

  return $builtins;
}

sub _load_ops (@map) {
  my %ops =
    map +($_->[0], [ @{$_->[1]}[1..$#{$_->[1]}] ]),
      grep @{$_->[1]} > 1,
        @map;
  \%ops;
}

1;
