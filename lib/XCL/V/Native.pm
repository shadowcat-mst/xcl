package XCL::V::Native;

use XCL::Class 'XCL::V';

async sub invoke_against ($self, $scope, $valp) {
  my ($ns, $method_name, $apply, $is_method, $unwrap, $res)
    = @{$self->data}{qw(ns native_name apply is_method unwrap)};
  load_class $ns if $ns;
  my $valp_u = $unwrap ? $valp->tail : $valp;
  my $vals = (
    $apply
      ? (not_ok($res = await $scope->eval_concat($valp_u)) ? return $res : $res->val)
      : $valp_u
  );
  if (my $cb = $self->data->{code}) {
    return await $cb->($scope, $vals);
  }
  if ($is_method) {
    return Err[ Name('WRONG_ARG_COUNT') => Int(0) ]
      unless my ($first, $rest) = $vals->ht;
    my $fval = $apply ? $first
      : not_ok($res = await $scope->eval_concat($first)) ? return $res : $res->val;
    return await $fval->$method_name(($apply ? () : $scope), $rest);
  }
  return await $ns->$method_name(($apply ? () : $scope), $vals);
}

sub display_data ($self, $depth) {
  return $self->SUPER::display_data(0) unless $depth;

  my $in_depth = $depth - 1;
  my $dproto = { %{$self->data} };

  if ($dproto->{native_name} and $dproto->{ns}) {
    my $name = String(join('::', @{$dproto}{qw(ns native_name)}));
    return 'Native('.$name->display(1).')';
  }

  my ($is_class, $is_fexpr) =
    $dproto->{native_name}||'' =~ /^((?:c_)?)f(x?)_(.*)/;
  my %data;
  $data{apply} = Bool(0+!!$dproto->{apply})
    if !defined($is_fexpr) or !!$dproto->{apply} eq $is_fexpr;
  $data{is_method} = Bool(0+!!$dproto->{is_method})
    if !defined($is_class) or !!$dproto->{is_method} eq $is_class;
  $data{unwrap} = Bool(0) unless $dproto->{unwrap};
  my $guts = (
    keys %data
      ? Dict{
          %data,
          map +($_ => String($dproto->{$_})),
            grep defined($dproto->{$_}), qw(ns native_name)
        }
      : String(join('::', @{$dproto}{qw(ns native_name)}))
  );
  return 'Native('.$guts->display($in_depth).')';
}

sub from_foreign ($class, $code) {
  my $wrapped = sub { $class->_call_foreign($code, @_) };
  $class->new(data => { apply => 1, code => $wrapped }, metadata => {});
}

async sub _call_foreign ($class, $code, $scope, $vals) {
  my $args = try do {
    $vals->to_perl;
  } catch {
    return Err [ Name('FOREIGN') => String('VALUES') => String($@) ];
  };
  my $ret = try do {
    $code->(@$args);
  } catch {
    return Err [ Name('FOREIGN') => String('INVOKE') => String($@) ];
  };
  if ($ret->$_can('AWAIT_IS_READY')) {
    try {
      $ret = await $ret;
    } catch {
      return Err [ Name('FOREIGN') => String('FUTURE') => String($@) ];
    }
  }
  return Err([ Name('NO_SUCH_VALUE') ]) unless defined($ret);
  return try do {
    Val(XCL::V->from_perl($ret));
  } catch {
    return Err [ Name('FOREIGN') => String('RETURN') => String($@) ];
  };
}

sub f_concat ($self, $lst) {
  return $_ for $self->_same_types($lst, 'List');
  ValF Curry([ $self, map $_->values, $lst->values ]);
}

1;
