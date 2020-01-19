use XCL::Builtins;
use XCL::Class -test;

bail_out unless try_ok { XCL::Builtins->ops };
bail_out unless try_ok { XCL::Builtins->builtins };

done_testing;
