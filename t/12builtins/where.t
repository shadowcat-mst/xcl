use xcl::test;

let d := %(:x 1, :y 0);

var r := 0;

where d.'y' { r := 1 }

is r 0 'false value runs no block';

where d.'z' { r := 1 }

is r 0 'missing value runs no block';

where d.'x' { r := 1 }

is r 1 'true value runs block';
