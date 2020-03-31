package XCL::V::PerlObject;

use XCL::Class 'XCL::V';

sub display_data ($self, $) { 'PerlObject('.$self->data.')' }

our %dotcache;
our %mcache;

# This won't work on e.g. a Mojolicious controller with helpers since
# can() is then per object, but I'll burn that bridge when I come to it.

sub _dot_methods_for ($me, $perl_class) {
  $dotcache{$perl_class} ||= do {
    $mcache{$perl_class} ||= {};
    XCL::V::Native->from_foreign(sub ($method_name) {
      $mcache{$perl_class}{$method_name} //= do {
        if (my $code = $perl_class->can($method_name)) {
          XCL::V::Native->from_foreign($code);
        } else {
          0;
        }
      } || undef; # 0 for //= to work, undef return to convert to Err
    });
  };
}

sub from_perl ($class, $obj) {
  my $dot_methods = $class->_dot_methods_for(ref($obj));
  $class->new(data => $obj, metadata => { dot_methods => $dot_methods });
}

sub to_perl { shift->data }

1;

