use Mojo::File 'path';
use XCL::Class -test;

my @pm = path('lib')
  ->list_tree
  ->map(sub { /^lib\/(.*\.pm)$/ })
  ->each(sub ($file, $) { 
      bail_out unless try_ok { require $file } "Loaded ok: ${file}";
    });

done_testing;
