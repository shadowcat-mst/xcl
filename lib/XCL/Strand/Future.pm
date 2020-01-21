package XCL::Strand::Future;

use Mojo::IOLoop;
use base qw(Future);

sub await { Mojo::IOLoop->singleton->one_tick }

1;
