use strictures 2;
use experimental 'signatures';

package XCL::Builtins {
  use XCL::Values;
  sub list { _list(@_) }
  sub block ($env, @args) {
    my $res;
    $env = $env->snapshot;
    foreach my $arg (@args) {
      $res = $arg->eval($env);
      return $res unless $res->is_ok;
    }
    return $res;
  }
  sub evaluate {
    my $res = _list(@_);
    return $res unless $res->is_ok;
    my ($thisenv, $thing) = @{$res->val->data};
    $thing->eval($thisenv);
  }
  sub set ($env, $set, $valproto) {
    my $place = $set->eval($env);
    return Err([ Name('NOT_SETTABLE') => String('FIXME') ])
      unless $place->can_set;
    my $valres = $valproto->eval($env);
    return $valres unless $valres->is_ok;
    return $place->set($valres->val);
  }
  sub val ($env, $name) {
    return Err([ Name('NOT_A_NAME') => String($name->type) ])
      unless $name->is('Name');
    my $_set = $env->curry::weak::set($name->data);
    return Result({
      err => List([ Name('INTRO_REQUIRES_SET') => String($name->data) ]),
      set => sub { $_set->(Val($_[0])) },
    });
  }
  sub var ($env, $name) {
    return Err([ Name('NOT_A_NAME') => String($name->type) ])
      unless $name->is('Name');
    my $_set = $env->curry::weak::set($name->data);
    return Result({
      err => List([ Name('INTRO_REQUIRES_SET') => String($name->data) ]),
      set => sub { $_set->(Var($_[0])) },
    });
  }
  sub id ($env, $thing) {
    $thing->eval($env);
  }
  sub fexpr ($env, $argspec, $block) {
    my (undef, @argspec) = @{$argspec->data->data};
    my @argnames = map $_->data, @argspec;
    Val(Fexpr({
      argnames => \@argnames,
      env => $env->snapshot,
      body => $block
    }));
  }
  sub lambda ($env, $argspec, $block) {
    my (undef, @argspec) = @{$argspec->data->data};
    my @argnames = map $_->data, @argspec;
    Val(Lambda({
      argnames => \@argnames,
      env => $env->snapshot,
      body => $block
    }));
  }
  sub current_env ($env) {
    Val($env);
  }
  sub is {
    my $res = _list(@_);
    return $res unless $res->is_ok;
    my ($thisval, $thing) = @{$res->val->data};
    return Err([ Name('NOT_A_STRING') => String($thing->type) ])
      unless $thing->is('String');
    return Bool($thisval->is($thing->data) ? 1 : 0);
  }
  sub dict ($env, @args) {
    my $res = _list(@_);
    return $res unless $res->is_ok;
    my @pairs = $res->val->values;
    return Err([ Name('NOT_PAIRS'), String('FIXME') ])
      if grep !($_->is('List') and @{$_->data} == 2), @pairs;
    return Val(Dict({
      map +($_->data->[0]->string->val->data, $_->data->[1]),
        @pairs
    }));
  }
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

sub XCL::Builtins::if ($env, $cond, $true, $false = undef) {
  my $denv = $env->derive;
  my $res = $cond->eval($denv);
  return $res unless $res->is_ok;
  my $bool = $res->val->bool;
  return $bool unless $bool->is_ok;
  if ($bool->val->data) {
    my $ret = $true->eval($denv);
    return defined($false) ? $ret : Val($ret);
  }
  return $false->eval($denv) if defined($false);
  return Val(Err([ Name('NO_SUCH_VALUE') => String('else') ]));
}

sub XCL::Builtins::while ($env, $cond, $body) {
  my $denv = $env->derive;
  my $did;
  WHILE: while (1) {
    my $res = $cond->eval($denv);
    return $res unless $res->is_ok;
    my $bool = $res->val->bool;
    return $bool unless $bool->is_ok;
    if ($bool->val->data) {
      $did ||= 1;
      my $benv = $denv->derive;
      my $res = $body->eval($benv);
      return $res unless $res->is_ok;
    } else {
      last WHILE;
    }
  }
  return Val(Bool($did));
}

sub XCL::Builtins::string ($env, @args) {
  my $res = _list(@_);
  return $res unless $res->is_ok;
  my $str = '';
  foreach my $el ($res->val->values) {
    my $res = $el->string;
    return $res unless $res->is_ok;
    $str .= $res->val->data;
  }
  return Val(String($str));
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

package XCL::Builtins::Call {
  use XCL::Values;
  sub make ($env, $lst) {
    my $proto = $lst->eval($env);
    return $proto unless $proto->is_ok;
    return Val(Call($proto->val));
  }
  sub list ($env, $call) {
    my $res = $call->eval($env);
    return $res unless $res->is_ok;
    my $data = $res->val->data;
    return Err([ Name('CALL_SHOULD_CONTAIN_LIST') => $data ])
      unless $data->is('List');
    return Val($data);
  }
}

package XCL::Builtins::List {
  use XCL::Values;
  sub make { _list(@_) }
  sub count_of ($env, $lst) {
    my $proto = $lst->eval($env);
    return $proto unless $proto->is_ok;
    return Val(Int(scalar @{$proto->val->data}));
  }
  sub map ($env, $lproto, $sym, $call) {
    my $lst_res = $lproto->eval($env);
    return $lst_res unless $lst_res->is_ok;
    my $name = $sym->data;
    my @val;
    foreach my $el ($lst_res->val->values) {
      my $denv = $env->derive($name => $el);
      my $res = $call->eval($denv);
      return $res unless $res->is_ok;
      push @val, $res->val;
    }
    return Val(List(\@val));
  }
}

package XCL::Builtins::Dict {
  use XCL::Values;
  sub pairs_of ($env, $dict) {
    my $proto = $dict->eval($env);
    return $proto unless $proto->is_ok;
    Val(List[ $proto->val->pairs ]);
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
