package XCL::Parse;

use XCL::Class;

our $SYMBOL_CHARS = q{!#$%&*+-./:<=>@\^_|~};

our $STRUCTURE = [
  script => [ sequence_of => 'statement', { separated_by => ';' } ],
  statement => [ list_of 
];

rwp 'source';

rwp 'tree';

rwp 'leaf';

# $p->parse(statement => "foo bar baz; quux fleem");

sub parse ($self, $type, $stmt) {
  local @{$self}{qw(source tree leaf)};
  $self->_set_source($stmt);
  $self->_set_leaf($self->_set_tree(my $t = []));
  $self->${\"consume_${type}"};
  return $self->tree;
}

sub consume_atom_list ($self) {
  my $s = $self->source;
  LOOP: {
    $s =~ s/^(\s+)//sm;
    my $ws = $1;
    $self->_set_source($s);
    if ($self->consume_atom) {
      $leaf->[-1][0]{ws_before} = $ws;
      next LOOP;
    }
  }
  $self->_set_source($s);
  $self->clear_leaf;
  return 1;
}

sub consume_symbol ($self) {
  return unless (my $s = $self->source) =~ /^[${SYMBOL_CHARS}]/;
  $s =~ s/^([$SYMBOL_CHARS]+)//;
  push @{$self->leaf}, [ {}, symbol => $s ];
  $self->_set_source($s);
  return 1;
}

sub consume_word ($self) {
  return unless (my $s = $self->source) =~ /^[a-zA_Z_]/;
  $s =~ s/^(\w+)// or die "FAIL";
  push @{$self->leaf}, [ {}, word => $1 ];
  $self->_set_source($s);
  return 1;
}

sub consume_number ($self) {
  return unless (my $s = $self->source) =~ /^[0-9]/;
  if ($s =~ s/^([0-9]+\.[0-9]+)//) {
    push @{$self->leaf}, [ {}, float => $1 ];
    $self->_set_source($s);
    return 1;
  } elsif ($s =~ s/^([0-9])//) {
    push @{$self->leaf}, [ {}, int => $1 ];
    $self->_set_source($s);
    return 1;
  }
  die "FAIL";
}

sub consume_atom ($self) {
  foreach my $poss (qw(symbol word number)) {
    return 1 if $self->${\"consume_${poss}"};
  }
  return;
}

sub consume_call ($self) {
  return unless (my $s = $self->source) =~ s/^\[//;
  push @{$self->leaf}, [ {}, call => my $leaf = [] ];
  $self->_set_leaf($leaf);
  $self->consume_atom_list;
  if ($self->source =~ s/^\s*\]//) {
    
  return 1;
}

1;
