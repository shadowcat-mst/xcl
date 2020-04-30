package XCL::V::Scope;

use Mojo::File qw(path);
use XCL::Weaver;
use XCL::Class 'XCL::V';

has weaver => sub { XCL::Weaver->new };

has 'allow_intro';

async sub eval ($self, $thing) {
  state $state_id = '000';
  my $op_id = ++$state_id;
  # theoretically harmless but complicated life before, await more tests
  #return await $thing->evaluate_against($self) unless DEBUG;
  my $is_basic = do {
    state %is_basic;
    $is_basic{ref($thing)} //= 0+!!(
      ref($thing)->can('evaluate_against')
        eq XCL::V->can('evaluate_against')
    );
  };
  return Val $thing if $is_basic;

  dynamically $Eval_Depth = $Eval_Depth + 1;
  dynamically $Am_Running = [ Name('eval') => $thing ];

  my $indent = '  ' x $Eval_Depth;
  my $prefix = "${indent}eval "; # $op_id ";
  if ($Eval_Depth and not $Did_Thing) {
    print STDERR " {\n" if DEBUG;
    $Did_Thing++;
  }
  print STDERR $prefix.$thing->display(DEBUG) if DEBUG;
  my $res = do {
    dynamically $Did_Thing = 0;
    my $tmp = await $thing->evaluate_against($self);
    print STDERR "${indent}\}" if DEBUG and $Did_Thing;
    $tmp;
  };
  unless ($res->is_ok) {
    my ($prop) = map $_ ? $_->data : [], $res->metadata->{propagated_through};
    $res = $res->new(%$res, metadata => {
      %{$res->metadata},
      propagated_through =>
        List[ String($thing->display(4)), @$prop ],
    });
  }
  print STDERR " ->\n${indent}  ".$res->display(DEBUG).";\n" if DEBUG;
  return $res;
}

sub get_place ($self, $key) {
  $self->data->get($key);
}

async sub get ($self, $key) {
  return $_ for not_ok my $res = await $self->get_place($key);
  my $val = $res->val;
  return $val if $val->is('Result');
  return await $val->invoke($self);
}

async sub set ($self, $key, $val) {
  $self->data->data->{$key} = $val;
  return $val if $val->is('Result');
  return await $val->invoke($self);
}

async sub _invoke ($self, $, $vals) {
  return Err([ Name('WRONG_ARG_COUNT') => Int(scalar $vals->values) ])
    unless (my ($string) = $vals->values) == 1;
  return Err([ Name('NOT_A_STRING') => String($string->type) ])
    unless $string->is('String');
  return await $self->get($string->data);
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

sub f_pairs ($self, $) { ValF List [ $self->data->pairs ] }

sub f_keys ($self, $) { ValF List [ $self->data->keys ] }

sub f_values ($self, $) { ValF List [ $self->data->values ] }

1;
