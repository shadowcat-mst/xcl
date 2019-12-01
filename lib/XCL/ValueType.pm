package XCL::ValueType;

use XCL::Class;

ro 'name';

ro [ qw(v_get v_set v_call v_discard) ] => (required => 0);

1;
