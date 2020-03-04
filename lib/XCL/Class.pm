package XCL::Class;

use Import::Into;
use XCL::Strand::Future;
use curry;
use Mojo::Base -strict, -signatures;

sub import ($, $superclass = '-base') {
  unless (caller eq 'XCL::Values') {
    XCL::Values->import::into(1);
  }
  Safe::Isa->import::into(1);
  if ($superclass eq '-test') {
    Test2::V0->import::into(1);
    $superclass = '-strict';
  }
  if ($superclass eq '-exporter') {
    Exporter->import::into(1, 'import');
    $superclass = '-strict';
  }
  Object::Tap->import::into(1);
  Mojo::Base->import::into(1, 'Mojo::Base', $superclass, -signatures);
  Future::AsyncAwait->import::into(1, future_class => 'XCL::Strand::Future');
  Syntax::Keyword::Dynamically->import::into(1);
  constant->import::into(1, Future => 'XCL::Strand::Future');
}

1;
