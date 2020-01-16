use Test2::V0;
use Mojo::Base -strict;
use XCL::Builtins;

bail_out unless try_ok { XCL::Builtins->ops };
bail_out unless try_ok { XCL::Builtins->builtins };

done_testing;
