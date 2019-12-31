package XCL::Reifier;

use strict;
use warnings;
use XCL::Values;
use XCL::Builtins;

sub reify_ast {
  my ($self, $type, @args) = @_;
  if ($type eq 'number') {
    my ($num) = map /\./ ? Float($_) : Int($_), $args[0];
    return $num;
  }
  if ($type eq 'word' or $type eq 'symbol') {
    return Name($args[0]);
  }
  if ($type eq 'string') {
    return String($args[0]);
  }
  if ($type eq 'call') {
    return Call(List[ map $self->reify_ast($_), @args ]);
  }
  if ($type eq 'list') {
    return Call(List([
      Native(\&XCL::Builtins::List::make),
        map {
          $_->is('Call') and @{$_->data->data} == 1
            ? $_->data->data->[0]
            : $_
        }
          map $self->reify_ast(@$_),
            @args
    ]));
  }
  if ($type eq 'block') {
    return Call(List([
      Native(XCL::Builtins->can($type)), map $self->reify_ast(@$_), @args
    ]));
  }
  die "what";
}

1;
