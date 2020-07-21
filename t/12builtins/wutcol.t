use xcl::test;

#let ?: := fexpr (scope, cond, case, @elsep) {
#  let condv := scope.eval(cond);
#  let cases := [ $(opwut ++ (elsep,
#    (case, @elsep),
#    (condv, case),
#  )) ];
#  let call := [ $(opwut ++ (condv, @cases)) ];
#  scope.eval call;
#}

#let ?: := fexpr (scope, cond, case, @elsep) {
#  let condv := scope.eval(cond);
#  let cases := wutcol elsep (case, @elsep) (\[\] ++ (condv), case);
#  let call := wutcol condv cases.0 cases.1;
#  scope.eval call;
#}

is [ ?: 1 2 3 ] 2;
is [ ?: 0 2 3 ] 3;

{
  let x := 1;
  is [ ?: x 1 2 ] 1;
}

is [ ?: 0 [ 1 + 2 ] [ 3 + 4 ] ] 7;

is [ ?: 1 [ 1 + 2 ] [ 3 + 4 ] ] 3;

is [ { let x := ?: 0 3 4; $x } ] 4;

is [ ?: 1 0 ] 1;
is [ ?: 0 3 ] 3;
