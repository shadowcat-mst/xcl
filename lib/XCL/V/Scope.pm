package XCL::V::Scope;

use Mojo::File qw(path);
use XCL::Weaver;
use XCL::Class 'XCL::V';

with 'XCL::V::Role::Indexable';

sub index_is { 'String' }

has weaver => sub { XCL::Weaver->new };

has 'intro_as';

our $state_id = '000';

async sub _eval ($self, $thing) {
  dynamically $Am_Running = [ Name('eval') => $thing ];
  my $op_id = ++$state_id;
  if (DEBUG) {
    my @vm_loc = (caller(3))[1..2];
    $vm_loc[0] = do {
      no warnings 'uninitialized';
      +{ reverse %INC }->{$vm_loc[0]//''} // $vm_loc[0];
    };
    print STDERR Call([
      Name('ENTER'), String($op_id), @$Am_Running
    ])->display(8)."\n";
    print STDERR Call([
      Name('VMLOC'), String($op_id), map XCL::V->from_perl($_), @vm_loc
    ])->display(8)."\n";
  }
  my $ret = await $thing->evaluate_against($self);
  if (DEBUG) {
    print STDERR Call([
      Name('LEAVE'), String($op_id), $ret
    ])->display(8)."\n";
  }
  return $ret;
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

async sub combine ($self, $thing, $lst) {
  dynamically $Am_Running = [ Name('combine') => $thing ];
  my $op_id = ++$state_id;
  if (DEBUG) {
    my @vm_loc = (caller(2))[1..2];
    $vm_loc[0] = do {
      no warnings 'uninitialized';
      +{ reverse %INC }->{$vm_loc[0]//''} // $vm_loc[0];
    };
    print STDERR Call([
      Name('ENTER'), String($op_id), @$Am_Running
    ])->display(8)."\n";
    print STDERR Call([
      Name('VMLOC'), String($op_id), map XCL::V->from_perl($_), @vm_loc
    ])->display(8)."\n";
  }
  my $ret = await $thing->invoke_against($self, $lst);
  if (DEBUG) {
    print STDERR Call([
      Name('LEAVE'), String($op_id), $ret
    ])->display(8)."\n";
  }
  return $ret;
}

async sub get ($self, $index) {
  $index = String($index) unless ref($index);
  return $_ for not_ok
    my $res = await $self->combine($self->data, List[$index]);
  return Err[ Name('MISMATCH') ] unless my $val = $res->val;
  return $val if $val->is('Result');
  return await $self->combine($val, List[]);
}

async sub set ($self, $index, $val) {
  $index = String($index) unless ref($index);
  if (my $intro = $self->intro_as) {
    return $_ for not_ok +await dot_call_escape(
      $self, $self->data, assign_via_call => List([$index]), $intro->($val)
    );
  } else {
    return $_ for not_ok
      my $res = await $self->combine($self->data, List[$index]);
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
  return await $self->combine($self->data, List[$index]);
}

sub derive ($self, $merge) {
  Scope(Dict({ %{$self->data->data}, %$merge }));
}

sub snapshot ($self) {
  Scope(Dict({ %{$self->data->data} }));
}

sub f_derive ($self, $lst) {
  if (my ($merge) = $lst->values) {
    return ValF $self->derive($merge->data);
  }
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
  await $self->combine($ans, List[]);
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
