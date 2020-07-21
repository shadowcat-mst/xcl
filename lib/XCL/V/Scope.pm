package XCL::V::Scope;

use Mojo::File qw(path);
use XCL::Weaver;
use XCL::Class 'XCL::V';

with 'XCL::V::Role::Indexable';

sub index_is { 'String' }

has weaver => sub { XCL::Weaver->new };

has 'intro_as';

#async sub eval ($self, $thing) {
#  state $state_id = '000';
#  my $op_id = ++$state_id;
#  # theoretically harmless but complicated life before, await more tests
#  #return await $thing->evaluate_against($self) unless DEBUG;
#  my $is_basic = do {
#    state %is_basic;
#    $is_basic{ref($thing)} //= 0+!!(
#      ref($thing)->can('evaluate_against')
#        eq XCL::V->can('evaluate_against')
#    );
#  };
#  return Val $thing if $is_basic;
#
#  dynamically $Eval_Depth = $Eval_Depth + 1;
#  dynamically $Am_Running = [ Name('eval') => $thing ];
#
#  my $indent = '  ' x $Eval_Depth;
#  my $prefix = "${indent}eval "; # $op_id ";
#  if ($Eval_Depth and not $Did_Thing) {
#    print STDERR " {\n" if DEBUG;
#    $Did_Thing++;
#  }
#  print STDERR $prefix.$thing->display(DEBUG) if DEBUG;
#  my $res = do {
#    dynamically $Did_Thing = 0;
#    my $f = $thing->evaluate_against($self);
#    if (DEBUG) {
#      $f = $f->catch(sub ($err, @) {
#        die "$err evaluating ".$thing->display(8)."\n"
#      });
#    }
#    my $tmp = await $f;
#    print STDERR "${indent}\}" if DEBUG and $Did_Thing;
#    if ($tmp->isa('XCL::V::Stream')) {
#      my $concat_f = $tmp->f_concat(undef);
#      if (DEBUG) {
#        $f = $f->catch(sub ($err, @) {
#          die "$err running concat on stream of ".$thing->display(8)."\n"
#        });
#      }
#      $tmp = await $concat_f;
#    }
#    $tmp;
#  };
#  unless ($res) {
#    die "undef return evaluating ".$thing->display(8)."\n";
#  }
#  unless ($res->is_ok) {
#    my ($prop) = map $_ ? $_->data : [], $res->metadata->{propagated_through};
#    $res = $res->new(%$res, metadata => {
#      %{$res->metadata},
#      propagated_through =>
#        List[ String($thing->display(4)), @$prop ],
#    });
#  }
#  print STDERR " ->\n${indent}  ".$res->display(DEBUG).";\n" if DEBUG;
#  return $res;
#}

async sub _eval ($self, $thing) {
  dynamically $Am_Running = [ Name('eval') => $thing ];
  await $thing->evaluate_against($self);
}

async sub eval ($self, $thing) {
  my $res = await $self->_eval($thing);
  return $res if $res->isa('XCL::V::Result');
  return await $res->f_concat(undef);
}

async sub eval_drop ($self, $thing) {
  my $res = await $self->_eval($thing);
  return $res if $res->isa('XCL::V::Result');
  return await $res->f_exhaust(undef);
}

async sub eval_start ($self, $thing) {
  my $res = await $self->_eval($thing);
  return $res if $res->isa('XCL::V::Result');
  return Val $res;
}

async sub get ($self, $index) {
  $index = String($index) unless ref($index);
  return $_ for not_ok
    my $res = await $self->data->invoke($self, List[$index]);
  return Err[ Name('MISMATCH') ] unless my $val = $res->val;
  return $val if $val->is('Result');
  return await $val->invoke($self, List[]);
}

async sub set ($self, $index, $val) {
  $index = String($index) unless ref($index);
  if (my $intro = $self->intro_as) {
    return $_ for not_ok +await dot_call_escape(
      $self, $self->data, assign_via_call => List([$index]), $intro->($val)
    );
  } else {
    return $_ for not_ok
      my $res = await $self->data->invoke($self, List[$index]);
    my $cur = $res->val;
    if ($cur->is('Result')) {
      return $_ for not_ok +await
        my $bres = dot_call_escape($self, $cur, 'eq' => $val);
      return Err[ Name('MISMATCH') ] unless $bres->data;
    } else {
      return $_ for not_ok +await dot_call_escape(
        $self, $cur, assign_via_call => List([]), $val
      );
    }
  }
  return await $self->data->invoke($self, List[$index]);
}

sub derive ($self, $merge) {
  Scope(Dict({ %{$self->data->data}, %$merge }));
}

sub snapshot ($self) {
  Scope(Dict({ %{$self->data->data} }));
}

sub f_snapshot ($self, $) {
  ValF $self->snapshot;
}

sub display_data ($self, $depth) {
  'Scope(...)',
  #'Scope('.$self->data->display($depth).')'
}

sub c_fx_current ($class, $scope, $lst) { ValF($scope) }

sub f_eval ($self, $lst) {
  $self->eval($lst->head);
}

sub f_call ($self, $lst) {
  $self->eval(Call [ $lst->values ]);
}

sub f_expr ($self, $lst) {
  $self->eval($lst->count > 1 ? Call [ $lst->values ] : $lst->head);
}

async sub eval_string_inscope ($self, $string) {
  my $ans = $self->weaver->parse(
    stmt_list => $string, 
    await($self->get('_OPS'))->val->to_perl
  );
  my $res;
  foreach my $stmt (@{$ans->data}) {
    $res = await $self->eval($stmt);
    return $res unless $res->is_ok;
  }
  return $res;
}

async sub eval_string ($self, $string) {
  my $ans = $self->weaver->parse(
    stmt_list => $string, 
    await($self->get('_OPS'))->val->to_perl
  );
  await $ans->invoke($self, List[]);
}

sub f_eval_string ($self, $lst) {
  $self->eval_string($lst->head->data);
}

sub eval_file_inscope ($self, $file) {
  $self->eval_string_inscope(path($file)->slurp);
}

sub eval_file ($self, $file) {
  $self->eval_string(path($file)->slurp);
}

sub f_eval_file ($self, $lst) {
  $self->eval_file($lst->head->data);
}

sub f_store ($self, $lst) {
  ValF $self->data($lst->values);
}

1;
