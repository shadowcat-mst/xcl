package XCL::Parser;

use XCL::Class;

has tokenizer => sub {
  require XCL::Tokenizer;
  XCL::Tokenizer->new
};

sub extract_atomish ($self, $this, @rest) {
  my ($type, $tok) = @$this;
  state %is_atomish = map +($_ => 1), qw(word symbol number string);
  if ($is_atomish{$type}) {
    return (\@rest, $this);
  }
  if (my ($start) = $type =~ /^start_(.*)$/) {
    return $self->${\"extract_${start}"}(@rest);
  }
  return ();
}

sub parse ($self, $type, $str) {
  my ($left, $parse) = $self->${\"extract_${type}"}(
    $self->tokenizer->tokenize($str)
  );
  die "ARGH" if @$left;
  return $parse;
}

sub extract_compoundish ($self, @toks) {
  my @compound;
  while (@toks and my ($now_toks, $thing) = $self->extract_atomish(@toks)) {
    push @compound, $thing;
    @toks = @$now_toks;
  }
  return () unless @compound;
  return (\@toks, $compound[0]) if @compound == 1;
  return (\@toks, [ compound => @compound ]);
}

sub _extract_spacecall ($self, $call_type, @toks) {
  my @spc;
  while (@toks) {
    my $type = $toks[0][0];
    if ($type eq 'ws' or $type eq 'comment') {
      my $t = shift @toks;
      if (@spc and $spc[-1][0] eq 'block' and $t->[1] =~ /\n/) {
        unshift @toks, [ semicolon => ';' ];
        last;
      }
      next;
    }
    if (my ($toks, $val) = $self->extract_compoundish(@toks)) {
      @toks = @$toks;
      push @spc, $val;
      next;
    }
    last;
  }
  return (@spc ? (\@toks, [ $call_type => @spc ]) : ());
}

sub _extract_combi ($self, $mid, $end, $call_type, $combi_type, @toks) {
  my @ret;
  while (@toks) {
    if (my ($toks, $val) = $self->_extract_spacecall($call_type, @toks)) {
      push @ret, $val;
      @toks = @$toks;
    }
    last unless @toks;
    if ($combi_type eq 'block'
      and @ret
      and $ret[-1][-1][0] eq 'block'
    ) {
      shift @toks;
      next;
    }
    my $type = $toks[0][0];
    shift @toks and last if $type eq $end;
    shift @toks and next if $type eq $mid;
    die "Invalid token type ${type} in ${combi_type}";
  }
  return (\@toks, [ $combi_type => @ret ]);
}

sub extract_stmt_list ($self, @toks) {
  $self->_extract_combi('semicolon', '', 'stmt', 'block', @toks);
}

sub extract_call ($self, @toks) {
  my ($toks, $call) = $self->_extract_spacecall('call', @toks);
  die "Confused" unless (shift @$toks)->[0] eq 'end_call';
  return ($toks, $call);
}
sub extract_list {
  shift->_extract_combi('comma', 'end_list', 'expr', 'list', @_)
}
sub extract_block {
  shift->_extract_combi('semicolon', 'end_block', 'stmt', 'block', @_)
}

1;
