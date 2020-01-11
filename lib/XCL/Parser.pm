package XCL::Parser;

use Mojo::Base -base, -signatures;

has tokenizer => sub {
  require XCL::Tokenizer;
  XCL::Tokenizer->new
};

sub extract_atomish ($self, $this, @rest) {
  my ($type, $tok) = @$this;
  if ($type eq 'word' or $type eq 'symbol' or $type eq 'number') {
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

sub _extract_spacecall ($self, $end, @toks) {
  my @spc;
  while (@toks) {
    my $type = $toks[0][0];
    if ($type eq 'ws' or $type eq 'comment') {
      my $t = shift @toks;
      last if @spc and $spc[-1][0] eq 'block' and $t->[1] =~ /\n/;
      next;
    }
    if (my ($toks, $val) = $self->extract_compoundish(@toks)) {
      @toks = @$toks;
      push @spc, $val;
      next;
    }
    last;
  }
  return (\@toks, (@spc ? [ call => @spc ] : ()));
}

sub _extract_combi ($self, $mid, $end, $combi_type, @toks) {
  my @ret;
  while (@toks) {
    if (my ($toks, $val) = $self->_extract_spacecall($end//'', @toks)) {
      push @ret, $val;
      @toks = @$toks;
    }
    last unless @toks;
    next if $combi_type eq 'block' and $ret[-1][-1][0] eq 'block';
    my $type = $toks[0][0];
    shift @toks and last if $type eq $end;
    shift @toks and next if $type eq $mid;
    die "Invalid token type ${type} in ${combi_type}";
  }
  return (\@toks, [ $combi_type => @ret ]);
}

sub extract_stmt_list ($self, @toks) {
  $self->_extract_combi(';', '', 'block', @toks);
}

sub extract_call { shift->_extract_spacecall('end_call', @_) }
sub extract_list { shift->_extract_combi('comma', 'end_list', 'list', @_) }
sub extract_block {
  shift->_extract_combi('semicolon', 'end_block', 'block', @_)
}

1;
