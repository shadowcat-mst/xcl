use xcl::test;

ok true 'True';

todo 'This is meant to fail' {
  ok false 'False';
}

is [ 1 + 2 ] 3 'Basic arithmetic';
