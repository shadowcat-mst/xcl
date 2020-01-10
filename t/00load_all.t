use strict;
use warnings;
use lib 'lib';
use Test2::V0;
use Mojo::File 'path';

my @pm = path('lib')->list_tree->grep(qr/\.pm$/)->each;

s/^lib\/// for @pm;

foreach my $file (@pm) {
  bail_out unless try_ok { require $file } "Loaded ok: ${file}";
}

done_testing;
