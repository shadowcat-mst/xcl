package XCL::ValueBuilders;

use strictures 2;
use experimental 'signatures';

use Exporter 'import';

our @EXPORT = qw(Int String Name Command);

sub Int ($v) { XCL::Value->new(type => 'Int', data => $v) }
sub String ($v) { XCL::Value->new(type => 'String', data => $v) }
sub Name ($v) { XCL::Value->new(type => 'Name', data => $v) }
sub Command ($v) { XCL::Value->new(type => 'Command', data => $v) }

1;
