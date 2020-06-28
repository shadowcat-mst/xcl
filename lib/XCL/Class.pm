package XCL::Class;

use Import::Into;
use curry;
use Async::Methods;
use Mojo::Base -strict, -signatures;

sub import ($, $superclass = 'Mojo::Base') {
  unless (caller eq 'XCL::Values') {
    XCL::Values->import::into(1);
  }
  if ($superclass !~ /^-/) { # normal class
    Role::Tiny::With->import::into(1);
    Class::Method::Modifiers->import::into(1);
  } elsif ($superclass eq '-test') {
    Test2::V0->import::into(1);
    $superclass = '-strict';
  } elsif ($superclass eq '-exporter') {
    Exporter->import::into(1, 'import');
    $superclass = '-strict';
  }
  Safe::Isa->import::into(1);
  Object::Tap->import::into(1);
  Mojo::Loader->import::into(1, qw(load_class));
  Mojo::Base->import::into(1, $superclass, -signatures);
  Future::AsyncAwait->import::into(1);
  Syntax::Keyword::Dynamically->import::into(1);
  Syntax::Keyword::Try->import::into(1, qw(try try_value));
  warnings->unimport('experimental');
  constant->import::into(1, Future => 'XCL::Strand::Future');
}

1;
