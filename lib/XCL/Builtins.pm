package XCL::Builtins;

use XCL::Values;
use Mojo::Base -base, -signatures, -async;

async sub c_fx_set {
  my ($class, $scope, $lst) = @_;
  my ($set, $valproto) = $lst->values;
  my $pres = await $set->evaluate_against($scope);
  return $pres unless $pres->is_ok;
  my $place = $pres->val;
  return Err([ Name('NOT_SETTABLE') => String('FIXME') ])
    unless $place->can_set;
  my $valres = await $valproto->evaluate_against($scope);
  return $valres unless $valres->is_ok;
  return $place->set($valres->val);
}

sub c_fx_id ($class, $scope, $thing) {
  $thing->evaluate_against($scope);
}

my $expand_ns = sub ($pkg, $ns) {
  map +($_ => Var(Native($pkg->can($_)))),
    grep /^[a-z]/,
    grep $pkg->can($_),
    CORE::keys %$ns;
};

use XCL::Values;

our $Builtins = Environment(Dict {
  $expand_ns->('XCL::Builtins', \%XCL::Builtins::),
  Call => Val(Environment(
    Dict(+{ $expand_ns->('XCL::Builtins::Call', \%XCL::Builtins::Call::) })
  )),
  List => Val(Environment(
    Dict(+{ $expand_ns->('XCL::Builtins::List', \%XCL::Builtins::List::) })
  )),
  Name => Val(Environment(
    Dict(+{ $expand_ns->('XCL::Builtins::Name', \%XCL::Builtins::Name::) })
  )),
  Dict => Val(Environment(
    Dict(+{ $expand_ns->('XCL::Builtins::Dict', \%XCL::Builtins::Dict::) })
  )),
});

{
  my $builtins = $Builtins->data->data;
  my %ops = (
    %XCL::Builtins::ops,
    add => '+', multiply => '*', subtract => '-', divide => '/',
    id => '$', dict => '%',
  );
  $builtins->{$ops{$_}} = $builtins->{$_}
    for CORE::keys %ops;
}

1;
