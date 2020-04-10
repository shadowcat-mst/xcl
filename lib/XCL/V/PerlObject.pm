package XCL::V::PerlObject;

use XCL::Class 'XCL::V';

sub bool ($self) { ValF True }

sub display_data ($self, $) { 'PerlObject('.$self->data.')' }

sub _make_perl_call ($method) {
  Native->from_foreign(
    $method =~ s/^list_//
      ? sub { [ shift->$method(@_) ] }
      : sub { shift->$method(@_) }
  );
}

sub from_perl ($class, $obj) {
  my $dot_methods = Native->from_foreign(\&_make_perl_call);
  $class->new(data => $obj, metadata => { dot_methods => $dot_methods });
}

sub to_perl { shift->data }

1;

