## `(scheme assume)`

This library is based on
[SRFI-145](https://srfi.schemers.org/srfi-145/).  It is not standard
R7RS library.

### Abstract

A means to denote the invalidity of certain code paths in a Scheme
program is proposed. It allows Scheme code to turn the evaluation into
a user-defined error that need not be signalled by the
implementation. Optimizing compilers may use these denotations to
produce better code and to issue better warnings about dead code.

### Reference

#### `(assume obj message ...)` syntax

This special form is an expression that evaluates to the value of obj
if obj evaluates to a true value. It is an error if obj evaluates to a
false value. In this case, implementations are encouraged to report
this error together with the messages to the user, at least when the
implementation is in debug or non-optimizing mode. In case of
reporting the error, an implementation is also encouraged to report
the source location of the source of the error.
