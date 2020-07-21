package XCL::Builtins;

use XCL::V::Scope;
use XCL::Builtins::Functions;
use XCL::Builtins::Builder;
use XCL::Class;

sub _builtin_map () {
  state @map = (

    '$' => [ 'id' ],
    ':' => [ 'pair' ],
    '^' => [ 'metadata' ],

    fexpr => [ 'Fexpr.make' ],
    lambda => [ 'Lambda.make' ],
    string => [ 'String.make' ],
    dict => [ 'Dict.make' ],

    'not' => [ 'Bool.not' ],
    '!' => [ 'Bool.not' ],

    '%' => [ 'dict' ],
    "\\" => [ 'escape' ],

    current_scope => [ 'Scope.current' ],

    #'**' => [ '.exp' => -5 ],

    '+' => [ '.plus', -10 ],
    '-' => [ '.minus', -10 ],
    '*' => [ '.multiply', -15 ],
    '/' => [ '.divide', -15 ],

    '<' => [ '.lt', -30 ],
    '>' => [ '.gt', -30 ],
    '<=' => [ '.le', -30 ],
    '>=' => [ '.ge', -30 ],

    '==' => [ '.eq', -35 ],
    '!=' => [ '.ne', -35 ],

    '++' => [ '.concat', -40 ],

    '//' => [ exists_or => -45 ],
    '&&' => [ '.and', -50 ],
    '||' => [ '.or', -55 ],

    '..' => [ 'Int.range', -60 ],

    '|' => [ '.pipe', -65, -1 ],

    '=' => [ assign => -70 ],
    ':=' => [ assign => -70 ],

    if => [ undef, -90, 0, 1 ],
    unless => [ undef, -90, 0, 1 ],
    '?:' => [ 'wutcol' ], # binop precedence TBD

    and => [ '.and', -80 ],
    or => [ '.or', -85 ],

    foreach => [ '.foreach', -95, 0, 1 ],
    forall => [ '.forall', -95, 0, 1 ],

    else => [ undef, -100 ],

    '=>' => [ lambda => 1 ],
    '.' => [ dot => 10 ],

  );
  map [ @map[$_*2,$_*2+1] ], 0 .. int $#map/2;
}

sub builtins ($class) {
  state $builtins = do {
    my $scope = XCL::Builtins::Builder::_load_builtins _builtin_map;
    $scope->eval_string_inscope(<<~'END');
      let(if) := fexpr (scope, cond, block) {
        let dscope := do scope.derive;
        ?: dscope.eval(cond) [do { dscope.call block; true }] false;
      }
      let(unless) := fexpr (scope, cond, block) {
        ?: scope.eval(cond) false [do { scope.call block; true }];
      }
      let maybe := fexpr (scope, @lst) {
        let res := catch_only NO_SUCH_VALUE scope.expr @lst;
        ?: res.is_ok() (res.val()) ();
      }
      let where := fexpr (scope, cond, block) {
        let dscope := do scope.derive;
        let res := catch_only NO_SUCH_VALUE dscope.eval cond;
        ?: [res.is_ok() and res.val()] [do { dscope.call block; true }] false;
      }
      {
        let m := ^List.'provides_methods';
        m.'map' := (self, cb) => {
          self.pipe x => { (cb x) }
        }
        m.'where' := (self, cb) => {
          let wcb := x => {
            let res := maybe cb x;
            ?: [ res and res.0 ] res ();
          }
          self.pipe wcb;
        }
      }
    END
    $scope;
  };
}

1;
