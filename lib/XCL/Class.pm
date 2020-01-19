package XCL::Class;

use Import::Into;
use Mojo::Base -strict, -signatures;
use XCL::Strand::Future;
use XCL::Values ();
use Future::AsyncAwait ();
use experimental;

sub import ($, $superclass = '-base') {
  XCL::Values->import::into(1);
  if ($superclass eq '-test') {
    Test2::V0->import::into(1);
    $superclass = '-strict';
  }
  Mojo::Base->import::into(1, 'Mojo::Base', $superclass);
  Future::AsyncAwait->import::into(1, future_class => 'XCL::Strand::Future');
  experimental->import('signatures');
}

1;
