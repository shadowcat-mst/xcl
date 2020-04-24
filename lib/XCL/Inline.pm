package XCL::Inline;

use Mojo::Util qw(monkey_patch);
use Filter::Util::Call;
use XCL::Builtins;

use XCL::Class;

has 'package';

has 'inline_xcl';

has scope => sub { XCL::Builtins->builtins };

sub import ($class) {
  my $targ = caller;
  my $self = $class->new(package => $targ);
  monkey_patch $targ, run_inline_xcl => $self->curry::run;
  filter_add(sub {
    filter_del();
    1 while filter_read();
    my $text = $_;
    $_ = 'run_inline_xcl(); 1;';
    $self->inline_xcl($text);
    return 1;
  });
}

sub run ($self) {
  my $res = $self->scope->await::eval_string($self->inline_xcl);
  die $res->err->display(8) unless $res->is_ok;
  return;
}

1;
