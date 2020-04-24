# RATIONALE

This document is meant to describe what xcl is, why it was created, what it
does, and how it works. It's also meant to help explain the technical decisions
and details or the project.

## About xcl

The xcl project provides a metalanguage (programming language) which itself
provides a powerful extensible object-oriented programming environment using a
simple and intuitive language syntax.

## Hello World

```
# in hello.xcl

use xcl::script;

let greeting = Value.concat 'hello' 'world';

say greeting;
```

This script uses the `xcl::script` package, which is the entrypoint into the
program. It is a Perl library which parses everyting after its declaration as
xcl code.

This is why xcl is referred to as a metalanguage, i.e. it's a
programming languages currently built atop the Perl programming language. While
xcl runs on Perl, its syntax is much more akin to JavaScript.

To run this script from the command-line you would execute the program just as
you would with any other Perl script. Using the Perl interpreter you would
simply `perl hello.xcl`. Here's what's happening when you do that:

...

## Organization

This following describes how this project is laid out, where to find what, and
what the different namespaces represent. All major components are declared
under the `XCL` namespace and stored under the `lib` directory.

### Namespaces

- `XCL`

This is the main namespace where you'll find the parser, tokenizer, and other
fundamental packages.

- `XCL::Builtins`

This namespace contains the core builtin functions registered in the default
initial scope.

- `XCL::Strand`

This namespace is reserved for future usage. This namespace will contain all
behavior related to the supported concurrency model(s), TBD. The term
_*strand*_ is meant to represent some "strand of execution" or concurrency and
is used as not to be confused with terms like "processes", "forks", "threads",
etc.

- `XCL::V`

This is the _*values*_ namespace, where the _*V*_ in _*XCL::V*_ stands for
_*value*_ class. These classes are where you can find the methods available to
xcl value objects.

### Important Files and Directories

```
lib
└── XCL
    ├── Builtins
    ├── Strand
    ├── V
    ├── Builtins.pm
    ├── Class.pm
    ├── Parser.pm
    ├── Reifier.pm
    ├── Tokenizer.pm
    ├── V.pm
    ├── Values.pm
    ├── Weaver.pm
    └── script.pm
```

## Contributing

Thanks for your interest in this project. We welcome all community
contributions! To install locally, follow the instructions in the
[README.md](./README.md) file.

## Questions, Suggestions, Issues/Bugs

Please post any questions, suggestions, issues or bugs to the [issue
tracker](../../issues) on GitHub.
