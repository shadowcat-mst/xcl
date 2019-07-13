package XCL::Class;

use strictures 2;
use Import::Into;

sub import {
  Mu->import::into(1);
  strictures->import(1, { version => 2 });
  experimental->import::into(1, 'signatures');
}

1;
