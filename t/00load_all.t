use Test2::V0;
use Mojo::Base -strict, -signatures;
use Mojo::File 'path';

my @pm = path('lib')
  ->list_tree
  ->map(sub { /^lib\/(.*\.pm)$/ })
  ->each(sub ($file, $) { 
      bail_out unless try_ok { require $file } "Loaded ok: ${file}";
    });

done_testing;
