use xcl::test;

#let maybe = fexpr (scope, @lst) {
#  let res = catch_only NO_SUCH_VALUE lst;
#  ?: res.is_ok() (res.val()) ();
#}

let d = %(:x 1);

is d('x') 1 'dict sanity';

is maybe(d.'x') (1) 'dict lookup';

is maybe(d.'y') () 'dict lookup failure';

let fail = result_of({ maybe(1+2.5) });

is fail.err().to_list().0 \TYPES_MUST_MATCH
  'non-NO_SUCH_VALUE error propagated';
