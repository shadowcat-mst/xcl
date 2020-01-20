package XCL::Builtins;

use XCL::V::Scope;
use XCL::Builtins::Functions;
use XCL::Builtins::Builder;
use XCL::Class;

sub _builtin_map () {
  state @map = (

    '$' => [ 'id' ],
    '?' => [ 'result_of' ],

    fexpr => [ 'Fexpr.make' ],
    lambda => [ 'Lambda.make' ],
    string => [ 'String.make' ],
    dict => [ 'Dict.make' ],
    escape => [ 'Escape.make' ],

    'not' => [ 'Bool.not' ],
    '!' => [ 'Bool.not' ],

    '%' => [ 'dict' ],
    "\\" => [ 'escape' ],

    current_scope => [ 'Scope.current' ],
    let => [ 'Scope.val_in_current' ],
    var => [ 'Scope.var_in_current' ],

    '**' => [ exp => -5 ],

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

    '&&' => [ '.and', -50 ],
    '||' => [ '.or', -55 ],

    '=' => [ set => -70 ],

    if => [ undef, -90, 0, 1 ],
    unless => [ undef, -90, 0, 1 ],

    and => [ '.and', -80 ],
    or => [ '.or', -85 ],

    foreach => [ '.foreach', -95, 0, 1 ],
    forall => [ '.forall', -95, 0, 1 ],

    else => [ undef, -100 ],

    '=>' => [ lambda => 1 ],
    '.' => [ dot => 10 ],

    # EXPERIMENT
    where => [ '.where', 15, 0 ],

    in => [ '.has_value', 20, 1 ],
  );
  map [ @map[$_*2,$_*2+1] ], 0 .. int $#map/2;
}

sub ops ($class) {
  state $ops = XCL::Builtins::Builder::_load_ops _builtin_map;
}

sub builtins ($class) {
  state $builtins = XCL::Builtins::Builder::_load_builtins _builtin_map;
}

1;
