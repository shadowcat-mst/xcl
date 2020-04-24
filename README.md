# NAME

xcl

# ABSTRACT

Extensible (Command | Control | Configuration) Language

# DESCRIPTION

This project provides the source for a metalanguage called xcl, which itself
provides a powerful extensible object-oriented programming environment using a
simple and intuitive language syntax.

# REQUIREMENTS

- Linux
- Perl 5.14+

# INSTALLATION

`cpanm -qn --installdeps .`

# INSTALLATION (FOR CONTRIBUTORS)

`cpanm -qn --installdeps .`

`cpanm -qn --installdeps --cpanfile=cpanfile-for-reply`

# RATIONALE

If you're a contributor, or familiar with the underlying technologies, and want
to understand the why and how of the language please read the following:

- [Rationale](RATIONALE.md)
- [Stability](STABILITY.md)

# TESTING

Tests for the application exist under the `t` directory and can be run using
the standard `prove` Perl testing application:

`prove -lrv t`

# AUTHOR

Matt Trout, `mstrout@cpan.org`

# LICENSE

Copyright (C) 2020, Matt S. Trout.

This is NOT free software; all rights reserved.
