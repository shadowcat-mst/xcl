package XCL::V::Stream;

use XCL::Class 'XCL::V';

async sub f_next ($self, $) {
  my $d = $self->data;
  return $_ for grep defined, $d->{done};
  my $gen = $d->{generator};
  return $d->{done} = $_ for not_ok my $res = await concat $gen->();
  return $d->{done} = $_ for not_ok my $bres = await concat $res->val->bool;
  return $d->{done} = $bres unless $bres->val->data;
  return $res;
}

async sub _fold ($self, $base, $f) {
  my $d = $self->data;
  my $r = $base;
  while (!$d->{done}) {
    return $_ for not_ok my $res = await concat $self->f_next(undef);
    $r = $f->($r, $res->val);
  }
  return $r;
}

sub f_exhaust ($self, $) {
  my $vtrue = Val True;
  $self->_fold($vtrue, sub { $vtrue });
}

sub f_concat ($self, $) {
  my ($base, $fold) = @{$self->data}{qw(base fold)};
  $self->_fold($base, $fold);
}

1;
