use strictures 2;
use experimental 'signatures';

BEGIN {
  local $XCL::V::Loading = 1;
  require XCL::Values;
}

package XCL::V {
  use XCL::Values;
  sub eval ($self, $env) { Val($self) }
  sub data ($self) { $self->{data} }
  sub metadata ($self) { $self->{metadata} }
  sub invoke ($self, @) {
    Err([ Name('CANT_INVOKE') => String($self->display) ])
  }
  sub is ($self, $type) {
    $self->isa("XCL::V::${type}");
  }
  sub type ($self) {
    (split '::', ref($self))[-1];
  }
  sub display ($self, @) { $self->type.'()' }
  sub bool ($self) { Err([ Name('CANT_BOOLEAN') => String($self->type) ]) }
  sub string ($self) { Err([ Name('CANT_STRINGIFY') => String($self->type) ]) }
}

BEGIN {
  foreach my $type (@XCL::Values::Types) {
    no strict 'refs';
    @{"XCL::V::${type}::ISA"} = qw(XCL::V);
  }
}

sub XCL::V::Escape::eval ($self, $env) { Val($self->data) }

sub XCL::V::Call::eval ($self, $env) {
  my ($command, @args) = @{$self->data->data};
  if ((my $res = $command->eval($env))->is_ok) {
    return $res->val->invoke($env, @args);
  } else {
    return $res;
  }
}

sub XCL::V::Call::display ($self, $depth) {
  return $self->SUPER::display(0) unless $depth;
  my $in_depth = $depth - 1;
  my @res;
  foreach my $val ($self->data->values) {
    push @res, $val->display($in_depth);
  }
  return '[ '.join(' ', @res).' ]';
}

sub XCL::V::Name::eval ($self, $env) { $env->get($self->data) }

sub XCL::V::Name::display ($self, @) { $self->data }

sub XCL::V::Fexpr::invoke ($self, @args) {
  my ($argnames, $env, $body) = @{$self->data}{qw(argnames env body)};
  my %merge; @merge{@$argnames} = map Val($_), @args;
  $body->eval($env->derive(\%merge));
}

sub XCL::V::Fexpr::display ($self, @) {
  return 'fexpr ('.join(', ', @{$self->data->{argnames}}).') { ... }';
}

sub XCL::V::Lambda::invoke ($self, $outer_env, @args) {
  my ($argnames, $env, $body) = @{$self->data}{qw(argnames env body)};
  my $argvalres = _list($outer_env, @args);
  return $argvalres unless $argvalres->is_ok;
  my %merge; @merge{@$argnames} = map Val($_), $argvalres->val->values;
  $body->eval($env->derive(\%merge));
}

sub XCL::V::Lambda::display ($self, @) {
  return 'lambda ('.join(', ', @{$self->data->{argnames}}).') { ... }';
}

sub XCL::V::Compound::eval ($self, $env) {
  my ($val, @rest) = @{$self->data};
  my $res = $val->eval($env);
  return $res unless $res->is_ok;
  while (my $v = shift @rest) {
    my @v = $v;
    if ($v->is('Call') and $v->data->data->[0]->data eq 'list') {
      @v = @{$v->data->data}[1..$#{$v->data->data}];
    }
    $res = $res->val->invoke($env, @v);
    return $res unless $res->is_ok;
  }
  return $res;
}

package XCL::V::Dict {
  use XCL::Values;
  sub get ($self, $key) {
    my $dict = $self->data;
    Result({
      ($dict->{$key}
        ? (val => $dict->{$key})
        : (err => List([ Name('NO_SUCH_VALUE') => String($key) ]))
      ),
      set => $self->curry::weak::set($key),
    });
  }
  sub set ($self, $key, $value) {
    return Val($self->data->{$key} = $value);
  }
  sub invoke ($self, $, $string, @) {
    return Err([ Name('NOT_A_STRING') => String($string->type) ])
      unless $string->is('String');
    $self->get($string->data);
  }
  sub has_key ($self, $key) {
    $self->data->{$key} ? 1 : 0;
  }
  sub keys ($self) {
    map String($_), sort CORE::keys %{$self->data};
  }
  sub values ($self) {
    @{$self->data}{sort CORE::keys %{$self->data}};
  }
  sub pairs ($self) {
    my $d = $self->data;
    return map List([ String($_), $d->{$_} ]), sort CORE::keys %$d;
  }
  sub display ($self, $depth) {
    return $self->SUPER::display(0) unless $depth;
    my $in_depth = $depth - 1;
    my @res;
    foreach my $key ($self->keys) {
      push @res, '('
        .$key->display($in_depth)
        .', '
        .$self->data->{$key->data}->display($in_depth)
        .')';
    }
    return '%('.join(', ', @res).')';
  }
}

sub XCL::V::Var::set_data ($self, $val) {
  Val($self->{data} = $val);
}

sub XCL::V::Var::invoke ($self, $env = undef) {
  my $set_data = $self->curry::weak::set_data;
  Result({
    val => $self->data,
    set => $set_data,
  });
}

sub XCL::V::Var::display ($self, $depth) {
  'Var('.$self->data->display($depth).')'
}

package XCL::V::Environment {
  use XCL::Values;
  sub get ($self, $key) {
    my $res = $self->data->get($key);
    return $res unless $res->is_ok;
    my $val = $res->val;
    return $val if $val->is('Result');
    return $val->invoke;
  }
  sub set ($self, $key, $value) {
    Val($self->data->data->{$key} = $value);
  }
  sub invoke ($self, $env, $string, @) {
    return Err([ Name('NOT_A_STRING') => String($string->type) ])
      unless $string->is('String');
    return $self->get($string->data);
  }
  sub derive ($self, $merge) {
    Environment(Dict({ %{$self->data->data}, %$merge }));
  }
  sub snapshot ($self) {
    Environment(Dict({ %{$self->data->data} }));
  }
  sub display ($self, $depth) {
    'Environment('.$self->data->display($depth).')'
  }
}

package XCL::V::List {
  use XCL::Values;
  sub get ($self, $idx) {
    die "NOT YET" if $idx < 0;
    my $ary = $self->data;
    Result({
     ($idx <= $#$ary
       ? (val => $ary->[$idx])
       : (err => List([ Name('NO_SUCH_VALUE') => Int($idx) ]))),
     (set => $self->curry::weak::set($idx)),
    });
  }
  sub set ($self, $idx, $value) {
    die "NOT YET" if $idx < 0;
    my $ary = $self->data;
    return Err([ Name('NO_SUCH_INDEX') => Int($idx) ]) if $idx > @$ary;
    return Val($ary->[$idx] = $value);
  }
  sub invoke ($self, $, $idx, @) {
    return Err([ Name('NOT_AN_INT') => String($idx->type) ])
      unless $idx->is('Int');
    $self->get($idx->data);
  }
  sub keys ($self) {
    my $ary = $self->data;
    return map Int($_), 0 .. $ary;
  }
  sub values ($self) {
    return @{$self->data};
  }
  sub display ($self, $depth) {
    return $self->SUPER::display(0) unless $depth;
    my $in_depth = $depth - 1;
    my @res;
    foreach my $val ($self->values) {
      push @res, $val->display($in_depth);
    }
    return '('.join(', ', @res).')';
  }
}

package XCL::V::Result {
  sub is_ok ($self) { exists $self->data->{val} }
  sub val ($self) { $self->data->{val} }
  sub err ($self) { $self->data->{err} }
  sub can_set ($self) { exists $self->data->{set} }
  sub set ($self, $value) {
    $self->data->{set}->($value);
  }
  sub display ($self, $depth) {
    if ($self->is_ok) {
      return 'Val('.$self->val->display($depth).')';
    }
    return 'Err('.$self->err->display($depth).')';
  }
}

sub XCL::V::Native::invoke ($self, @args) { $self->data->(@args) }

sub XCL::V::Bool::bool ($self) { Val($self) }

sub XCL::V::List::bool ($self) { Val(Bool(@{$self->data} ? 1 : 0)) }

sub XCL::V::Dict::bool ($self) {
  Val(Bool(CORE::keys(%{$self->data}) ? 1 : 0))
}

sub XCL::V::String::bool ($self) { Val(Bool(length($self->data) ? 1 : 0)) }

sub XCL::V::Int::bool ($self) { Val(Bool($self->data == 0 ? 0 : 1)) }
sub XCL::V::Float::bool ($self) { Val(Bool($self->data == 0 ? 0 : 1)) }

sub XCL::V::String::string ($self) { Val($self) }
sub XCL::V::String::display ($self, @) { q{'}.$self->data.q{'} }

sub XCL::V::Int::string ($self) { Val(String($self->display)) }
sub XCL::V::Int::display ($self, @) { ''.$self->data }

sub XCL::V::Float::string ($self) { Val(String($self->display)) }
sub XCL::V::Float::display ($self, @) {
  my $str = ''.$self->data;
  if ($str =~ /^-?[0-9]+$/) { return "${str}.0" }
  return $str;
}

sub XCL::V::Bool::string ($self) {
  Val(String($self->display))
}

sub XCL::V::Bool::display ($self, @) {
 $self->data ? 'true' : 'false'
}

1;
