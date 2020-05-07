package XCL::Builtins::Builder;

use XCL::V::Scope;
use XCL::Builtins::Functions;
use XCL::Class -exporter;

our @EXPORT_OK = qw(
  _construct_builtin
  _explode_name
  _builtin_names_of
  _nonbuiltin_names_of
  _sub_names_of
  _builtins_of
  _value_builtins
  _value_type_builtins
  _assemble_value
  _load_builtins
  _load_ops
);

sub _construct_builtin (
  $namespace, $stash_name, $is_class, $is_fexpr, $f_name, $cls_unwrap = 0
) {
  my $metadata = {};
  if (my $method = $namespace->can("metadata_for_${stash_name}")) {
    $metadata = $namespace->$method;
  }
  Native(
    {
      apply => 0+!$is_fexpr,
      is_method => 0+!$is_class,
      unwrap => 0+!!($is_class and $cls_unwrap),
      ns => $namespace,
      native_name => $stash_name,
    },
    $metadata
  );
}

sub _explode_name ($stash_name) {
  if (my @explode = $stash_name =~ /^((?:c_)?)f(x?)_(.*)/) {
    return [ $stash_name, @explode ];
  }
  return ();
}

sub _builtin_names_of ($namespace) {
  load_class $namespace;
  no strict 'refs';
  return +(map _builtin_names_of($_), @{"${namespace}::ISA"}),
    map +(_explode_name $_),
      _sub_names_of($namespace);
}

sub _nonbuiltin_names_of ($namespace) {
  return grep !_explode_name($_), _sub_names_of($namespace);
}

sub _sub_names_of ($namespace) {
  no strict 'refs';
  return grep { $namespace->can($_) } keys %{"${namespace}::"};
}

sub _builtins_of ($namespace, $unwrap = 0) {
  return +{
    map +(
      $_->[3]
       => _construct_builtin $namespace, @$_, $unwrap
    ), _builtin_names_of $namespace
  };
}

sub _builtins_for_class ($name, $class) {
  my %b = %{_builtins_of $class, 'unwrap'};
  my (%has, %provides);
  ($b{$_}->data->{is_method} ? \%provides : \%has)->{$_} = $b{$_}
    for sort keys %b;
  return Val Name(
    $name, {
      has_methods => Dict(\%has),
      provides_methods => Dict(\%provides)
    }
  );
}

sub _assemble_value ($builtins, $to) {
  my @bits = split /\./, $to;
  if (@bits > 1) {
    my $scope = Scope(Dict $builtins);
    my $dotf = XCL::Builtins::Functions->c_fx_dot(
      $scope,
      List [ map Name($_), grep length, @bits ]
    )->get;
    return $to =~ /^\./ ? $dotf->val->await::invoke($scope, List[]) : $dotf;
  }
  return $builtins->{$bits[0]};
}

sub _load_builtins (@map) {

  my $functions = _builtins_of 'XCL::Builtins::Functions';

  my $builtins = { map +($_ => Val($functions->{$_})), keys %$functions };

  $builtins->{Value} = _builtins_for_class Value => 'XCL::V';

  $builtins->{true} = Val True;
  $builtins->{false} = Val False;

  foreach my $vtype (@XCL::Values::Types) {
    my $vb = _builtins_for_class $vtype => "XCL::V::${vtype}";
    $vb->val->metadata->{dot_via} = Name('Name');
    $builtins->{$vtype} = $vb;
  }

  foreach my $thing (grep defined $_->[1][0], @map) {
    my ($alias, $to) = @$thing;
    my $v = $builtins->{$alias} = _assemble_value $builtins, $to->[0];
    my $ns = 'XCL::Builtins::Functions';
    if (my $method = $ns->can("metadata_for_alias_${alias}")) {
      $v->val->metadata($ns->$method);
    }
  }
  $builtins->{'_OPS'} = Val(XCL::V->from_perl(_load_ops(@map)));
  return Scope Dict $builtins;
}

sub _load_ops (@map) {
  my %ops =
    map +($_->[0], [ @{$_->[1]}[1..$#{$_->[1]}] ]),
      grep @{$_->[1]} > 1,
        @map;
  \%ops;
}

1;
