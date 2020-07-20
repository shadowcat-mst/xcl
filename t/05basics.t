use XCL::Class -test;

my ($three, $four) = (Int(3), Int(4));

my $int_plus = Native {
  apply => 1,
  is_method => 1,
  native_name => 'f_plus',
};

my $scope = Scope Dict { '+' => Val $int_plus };

is $scope->eval(Call[ Name('+'), $three, $four ])->get, Val(Int 7);

$scope = Scope Dict {
  '.' => Val(Native({
    ns => 'XCL::Builtins::Dot',
    native_name => 'c_fx_dot',
  })),
  Int => Val(Name('Int', {
    provides_methods => Dict { plus => Native { %{$int_plus->data} } }
  })),
};

my $curried = $scope->eval(Call([ Name('.'), $three, Name('plus') ]))
                    ->get->val;

is $curried->invoke($scope, List[ $four ])->get, Val(Int 7);

is(
  $scope->eval(Call[ Call([ Call([ Name('.'), Name('plus') ]) ]), $three, $four ])->get,
  Val(Int 7)
);


done_testing;
