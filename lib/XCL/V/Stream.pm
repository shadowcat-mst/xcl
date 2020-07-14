package XCL::V::Stream;

use XCL::Class 'XCL::V';

async sub f_next ($self, $) {
  my $d = $self->data;
  return $_ for grep defined, $d->{done};
  my $gen = $d->{generator};
  $d->{done} = $_ for not_ok my $res = await concat $gen->();
  return $res;
}

async sub _fold ($self, $base, $f) {
  my $d = $self->data;
  my $r = $base;
  while (!$d->{done}) {
    return $_ for not_ok_except
      NO_SUCH_VALUE => my $res = await concat $self->f_next(undef);
    next unless $res->is_ok;
    $r = $f->($r, $res->val);
  }
  return $r;
}

sub f_exhaust ($self, $) {
  my $vtrue = Val True;
  $self->_fold($vtrue, sub { $vtrue });
}

sub f_concat ($self, $) {
  my $base = Val List [];
  $self->_fold($base, sub ($acc, $new) {
    Val List [ @{$acc->val->data}, $new ];
  });
}

1;
