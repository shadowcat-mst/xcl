package XCL::Builtins;

use XCL::V::Scope;
use XCL::Values;
use XCL::Builtin::Functions;
use Mojo::Base -base, -signatures, -async;

sub _load_ops () {
  my %ops = (
    '**' => [ -5, -1 ],
    '+' => [ -10, -1 ],
    '-' => [ -10, -1 ],
    '*' => [ -15, -1 ],
    '/' => [ -15, -1 ],
    '++' => [ -20, -1 ],
    +(map +($_ => [ -30, -1 ]), qw(> < >= <=)),
    +(map +($_ => [ -35, -1 ]), qw(== !=)),
    '&&' => [ -50, 0 ],
    '||' => [ -55, 0 ],
    '..' => [ -60, 0 ],
    'where' => [ -65, 0 ],
    '=' => [ -70, 0 ],
    'and' => [ -80, 0 ],
    'or' => [ -85, 0 ],
    'if' => [ -90, 0, 1 ],
    'unless' => [ -90, 0, 1 ],

    'for' => [ -95, 0, 1 ],
    'forall' => [ -95, 0, 1 ],

    'else' => [ -100, -1 ],

    '.' => [ 10, 0 ],
    '=>' => [ 15, 0 ],
    'in' => [ 20, 0 ],
  );
  \%ops;
}

sub _builtin_map () {
  return (

    '=' => 'set',
    '.' => 'dot',

    fexpr => 'Fexpr.make',
    lambda => 'Lambda.make',
    string => 'String.make',
    dict => 'Dict.make',
    escape => 'Escape.make',

    '%' => 'dict',
    "\\" => 'escape',
    '=>' => 'lambda',

    current_scope => 'Scope.current',
    let => 'Scope.val_in_current',
    var => 'Scope.var_in_current',

    '==' => '.eq',
    '!=' => '.ne',

    '<' => '.lt',
    '>' => '.gt',
    '>=' => '.ge',
    '<=' => '.le',

    '+' => '.plus',
    '-' => '.minus',
    '*' => '.multiply',
    '/' => '.divide',

    '++' => '.concat',

    '||' => '.or',
    '&&' => '.and',
    or => '.or',
    and => '.and',

    '$' => 'id',
    '?' => 'result_of',

    'not' => 'Bool.not',
    '!' => 'Bool.not',

    for => '.for',
    forall => '.forall',
  );
}

sub _construct_builtin ($namespace, $stash_name, $cls_unwrap = 0) {
  my ($is_class, $fexpr, $name) = $stash_name =~ /^((?:c_)?)_f(x?)_(.*)/;
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
      grep /^(?:c_)?_fx?_./,
        sort do { no strict 'refs'; keys %{"${namespace}::"} };
}

sub _builtins_of ($namespace, $unwrap = 0) {
  return +{
    map +(
      $_ =~ /^(?:c_)?_fx?_(.+)$/
       => _construct_builtin $namespace, $_, $unwrap
    ), _builtin_names_of $namespace
  };
}

sub _load_builtins () {

  my $builtins = _builtins_of 'XCL::Builtin::Functions';

  $builtins->{Value} = Val Name(
    Value => {
      dot_methods => Dict(my $vbase = _builtins_of 'XCL::V', 'unwrap')
    }
  );

  foreach my $vtype (@XCL::Values::Types) {
    my $vbuiltins = _builtins_of "XCL::V::${vtype}", 'unwrap';
    $builtins->{$vtype} = Val Name(
      $vtype, { dot_methods => Dict({ %$vbase, %$vbuiltins }) }
    );
  }

  my $scope = Scope $builtins;

  my @map = _builtin_map();

  while (my ($alias, $to) = splice @map, 0, 2) {
    my @bits = split /\./, $to;
    my $thing = do {
      if (@bits > 1) {
        XCL::V::Builtin::Functions->c_fx_dot(
          $scope,
          List [ map String($_), grep length, @bits ]
        )->get->val;
      } else {
        $builtins->{$bits[0]}
      }
    };
    $builtins->{$alias} = $thing;
  }

  return $builtins;
}

sub ops ($class) {
  state $ops = _load_ops;
}

sub builtins ($class) {
  state $builtins = _load_builtins;
}

1;
