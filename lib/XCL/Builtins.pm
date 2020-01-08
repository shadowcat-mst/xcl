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

package XCL::Builtins {
  my $MAX_SAFE_INT = 2**53;
  sub add {
    my $res = _list(@_);
    return $res unless $res->is_ok;
    my ($first, @rest) = $res->val->values;
    my $type = ref($first);
    return Err([
      Name('TYPES_MUST_MATCH') => map String($_->type), ($first, @rest)
    ]) if grep ref($_) ne $type, @rest;
    my $acc = $first->data;
    foreach my $val (map $_->data, @rest) {
      if ($type =~ /Int$/ and $MAX_SAFE_INT - $acc < $val) {
        return Err([ Name('INT_OVERFLOW') ]);
      }
      $acc += $val;
    }
    Val(bless({ data => $acc }, $type));
  }
  sub multiply {
    my $res = _list(@_);
    return $res unless $res->is_ok;
    my ($first, @rest) = $res->val->values;
    my $type = ref($first);
    die "Incorrect types" if grep ref($_) ne $type, @rest;
    my $acc = $first->data;
    foreach my $val (map $_->data, @rest) {
      if ($type =~ /Int$/ and $MAX_SAFE_INT / $acc > $val) {
        return Err([ Name('INT_OVERFLOW') ]);
      }
      $acc *= $val;
    }
    Val(bless({ data => $acc }, $type));
  }
  sub subtract {
    my $res = _list(@_);
    return $res unless $res->is_ok;
    my ($l, $r) = $res->val->values;
    # type check here
    Val(bless({ data => $l->data - $r->data }, ref($l)));
  }
  sub divide {
    my $res = _list(@_);
    return $res unless $res->is_ok;
    my ($l, $r) = $res->val->values;
    # type check here (numeric is enough)
    Val(Float($l->data / $r->data));
  }
  sub int {
    my $res = _list(@_);
    return $res unless $res->is_ok;
    my ($v) = $res->val->values;
    return Err([ Name('BAD_TYPE') => String($v->type) ])
      unless $v->is('Int') or $v->is('Float');
    return Val(Int(int($v->data)));
  }
  sub float {
    my $res = _list(@_);
    return $res unless $res->is_ok;
    my ($v) = $res->val->values;
    return Err([ Name('BAD_TYPE') => String($v->type) ])
      unless $v->is('Int') or $v->is('Float');
    return Val(Float($v->data));
  }
}

package XCL::Builtins {
  BEGIN {
    our %ops = (
      gt => '>', ge => '>=', lt => '<', le => '<=',
      eq => '==', ne => '!=',
    );
    foreach my $key (sort keys %ops) {
      my $numop = $ops{$key};
      eval 'sub '.$key.' {
        my $res = _list(@_);
        return $res unless $res->is_ok;
        my ($l, $r) = $res->val->values;
        if ($l->is("Int") or $l->is("Float")) {
          return Err([ Name("VALUE_TYPE") => String($r->type) ])
            unless $r->is("Int") or $r->is("Float");
          return Val(Bool(($l->data '.$numop.' $r->data) ? 1 : 0));
        }
        return Err([ Name("VALUE_TYPE") => String($l->type) ])
          unless $l->is("String");
        return Err([ Name("VALUE_TYPE") => String($r->type) ])
          unless $r->is("String");
        return Val(Bool(($l->data '.$key.' $r->data)));
      } 1' or die "Compilation failed for ${key}: $@";
    }
  }
}

package XCL::Builtins::Name {
  use XCL::Values;
  sub to_string ($env, $name) {
    Val(String($name->data));
  }
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
