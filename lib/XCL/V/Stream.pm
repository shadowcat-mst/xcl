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
  $self->_fold($vtrue, async sub { Val $vtrue });
}

sub f_concat ($self, $) {
  my $base = List [];
  $self->_fold($base, async sub ($acc, $new) {
    Val List [ @{$acc->val->data}, $new ];
  });
}

1;
