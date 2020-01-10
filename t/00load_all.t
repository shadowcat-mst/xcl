use strict;
use warnings;
use lib 'lib';
use Test2::V0;
use experimental 'signatures';
use Mojo::File 'path';

my @pm = path('lib')
  ->list_tree
  ->map(sub { /^lib\/(.*\.pm)$/ })
  ->each(sub ($file, $) { 
      bail_out unless try_ok { require $file } "Loaded ok: ${file}";
    });

done_testing;
