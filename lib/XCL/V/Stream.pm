package XCL::V::Stream;

use XCL::Class 'XCL::V';

async sub f_next ($self, $) {
  my $d = $self->data;
  return $_ for grep defined, $d->{done};
  my $gen = $d->{generator};
  $d->{done} = $_ for not_ok my $res = await $gen->();
  return $res;
}

async sub _fold ($self, $base, $f) {
  my $d = $self->data;
  my $r = Val $base;
  while (!$d->{done}) {
    return $_ for not_ok_except
      NO_SUCH_VALUE => my $res = await $self->f_next(undef);
    next unless $res->is_ok;
    $r = await $f->($r, $res->val);
  }
  return $r;
}

sub f_exhaust ($self, $) {
  my $vtrue = True;
  $self->_fold(True, async sub { Val $vtrue });
}

sub f_concat ($self, $) {
  $self->_fold(List([]), async sub ($acc, $new) {
    Val List [ @{$acc->val->data}, $new ];
  });
}

async sub fx_pipe ($self, $scope, $lstp) {
  return $_ for not_ok my $lres = await $scope->eval($lstp);
  my $cb = $lres->val->head;
  my @queue;
  my $pipegen = async sub {
    return Val $_ for grep defined, shift @queue;
    while (1) {
      return $_ for not_ok my $nres = await $self->f_next(undef);
      return $_ for
        not_ok my $res = await $cb->invoke($scope, List[$nres->val]);
      my $val = $res->val;
      my @val = $val->is('List') ? $val->values : $val;
      if (my $next = shift @val) {
        push @queue, @val;
        return Val $next;
      }
    }
  };
  Stream({ generator => $pipegen });
}

1;
