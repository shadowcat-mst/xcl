grammar XCL::Grammar {
  token TOP { <statementlist> }
  token word { <[a..zA..Z]> <[a..zA..Z0..9_]>* }
  token symbol { <-[\s\w;,()\[\]{}'"]>+ }
  token list { '(' <.ws> <expr>* %% [ <.ws> ',' <.ws> ] ')' }
  token block { '{' <.ws> <statementlist> <.ws> '}' }
  token command { '[' <.ws> <statement> <.ws> ']' }
  token element {
    <word> | <symbol>
    | <list> | <block> | <command>
    | <qstring> | <qqstring>
  }
  token compound { <element>+ }
  rule expr { <compound> + }
  rule statement { <compound> + }
  rule statementlist { <statement> + %% ';' }

  token qstring { "'" [ <qescape> | <qstr> ]+ "'" }
  token qescape { \\ . }
  token qstr { <-[\\']>+ }

  token qqstring { '"' [ <qqescape> | <qqinterp> | <qqstr> ]+ '"' }
  token qqstr { <-[\\"$]>+ }
  token qqescape { \\ <qqescapechar> [ <list> | block ]? }
  token qqescapechar { . }
  token qqinterp { '$' [ <list> | <command> | <word> ] }
}

class XCL::Actions {

  method TOP ($/) { make [ 'script', $<statementlist>.made ] }

}

my $xcl = XCL::Grammar.new(); # :actions(XCL::Actions.new));

say $xcl.parse('foo bar($x , y, )+z; baz');

say $xcl.parse('for x in [ lines_of stdin ] { foo; bar; baz }');

say $xcl.parse("'foo \\x \\ \\' bar'");

say $xcl.parse('"foo \x \y\( \z(baz) bar $(a) $[b c] $d quux"');

say $xcl.parse('"some stuff \U("other stuff") more stuff"');
