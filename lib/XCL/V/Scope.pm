package XCL::V::Scope;

use XCL::Class 'XCL::V';

async sub eval ($self, $thing) {
  state $state_id = '000';
  my $op_id = ++$state_id;
  return await $thing->evaluate_against($self) unless DEBUG;
  my $is_basic = do {
    state %is_basic;
    $is_basic{ref($thing)} //= 0+!!(
      ref($thing)->can('evaluate_against')
        eq XCL::V->can('evaluate_against')
    );
  };
  return Val $thing if $is_basic;

  my $this_depth = $Eval_Depth + 1;
  dynamically $Eval_Depth = $this_depth;

  my $indent = '  ' x $Eval_Depth;
  my $prefix = "${indent}eval "; # $op_id ";
  if ($Eval_Depth and not $Did_Thing) {
    print STDERR " {\n";
    $Did_Thing++;
  }
  print STDERR $prefix.$thing->display(-1);
  my $res = do {
    dynamically $Did_Thing = 0;
    my $tmp = await $thing->evaluate_against($self);
    print STDERR "${indent}\}" if $Did_Thing;
    $tmp;
  };
  print STDERR " ->\n${indent}  ".$res->display(-1).";\n";
  return $res;
}

async sub get ($self, $key) {
  my $res = $self->data->get($key);
  return Err($res->data->{err}) unless $res->is_ok;
  my $val = $res->val;
  return $val if $val->is('Result');
  return await $val->invoke($self, List []);
}

async sub set ($self, $key, $val) {
  $self->data->data->{$key} = $val;
  return $val if $val->is('Result');
  return await $val->invoke($self, List []);
}

sub _invoke ($self, $, $vals) {
  return ErrF([ Name('WRONG_ARG_COUNT') => Int(scalar $vals->values) ])
    unless (my ($string) = $vals->values) == 1;
  return ErrF([ Name('NOT_A_STRING') => String($string->type) ])
    unless $string->is('String');
  return ResultF $self->get($string->data);
}

sub derive ($self, $merge) {
  Scope(Dict({ %{$self->data->data}, %$merge }));
}

sub snapshot ($self) {
  Scope(Dict({ %{$self->data->data} }));
}

sub display_data ($self, $depth) {
  'Scope('.$self->data->display($depth).')'
}

sub c_fx_val_in_current ($class, $self, $lst) { $self->intro(\&Val, $lst); }
sub c_fx_var_in_current ($class, $self, $lst) { $self->intro(\&Var, $lst); }

sub fx_val ($self, $, $lst) { $self->intro(\&Val, $lst); }
sub fx_var ($self, $, $lst) { $self->intro(\&Var, $lst); }

sub intro ($self, $type, $lst) {
  my ($name) = @{$lst->data};
  return ErrF([ Name('NOT_A_NAME') => String($name->type) ])
    unless $name->is('Name');
  my $_set = $self->curry::weak::set($name->data);
  return ResultF( Result {
    err => List([ Name('INTRO_REQUIRES_SET') => String($name->data) ]),
    set => sub { $_set->($type->($_[0])) },
  });
}

sub c_fx_current ($class, $scope, $lst) { ValF($scope) }

sub f_eval ($self, $, $lst) {
  $self->eval($lst->data->[0]);
}

sub f_call ($self, $, $lst) {
  $self->eval(Call [ @{$lst->data} ]);
}

1;
