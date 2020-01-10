package XCL::Parser;

use strict;
use warnings;

sub extract_atomish {
  my ($self, $this, @rest) = @_;
  my ($type, $tok) = @$this;
  if ($type eq 'word' or $type eq 'symbol' or $type eq 'number') {
    return (\@rest, $this);
  }
  if (my ($start) = $type =~ /^start_(.*)$/) {
    return $self->${\"extract_${start}"}(@rest);
  }
  return ();
}

sub extract_compoundish {
  my ($self, @toks) = @_;
  my @compound;
  while (my ($now_toks, $thing) = $self->extract_atomish(@toks)) {
    push @compound, $thing;
    @toks = @$now_toks;
  }
  return () unless @compound;
  return (\@toks, $compound[0]) if @compound == 1;
  return (\@toks, [ compound => @compound ]);
}

sub _extract_spacecall {
  my ($self, $end, @toks) = @_;
  my @spc;
  while (@toks) {
    my $type = $toks[0][0];
    if ($type eq 'ws' or $type eq 'comment') {
      shift @toks;
      next;
    }
    last if $type eq $end;
    if (my ($toks, $val) = $self->extract_compoundish(@toks)) {
      @toks = @$toks;
      push @spc, $val;
      next;
    }
    last;
  }
  return (\@toks, (@spc ? [ call => @spc ] : ()));
}

sub _extract_combi {
  my ($self, $mid, $end, $combi_type, @toks) = @_;
  my @ret;
  while (@toks) {
    if (my ($toks, $val) = $self->_extract_spacecall('', $end, @toks)) {
      push @ret, $val;
      @toks = @$toks;
    }
    my $type = $toks[0][0];
    last if $type eq $end;
    next if $type eq $mid;
    die "Invalid token type ${type} in ${combi_type}";
  }
  return (@toks, [ $combi_type => @ret ]);
}

sub extract_call { shift->_extract_spacecall(']', @_) }
sub extract_list { shift->_extract_combi(',', ')', 'list', @_) }
sub extract_block { shift->_extract_combi(';', '}', 'block', @_) }

1;
