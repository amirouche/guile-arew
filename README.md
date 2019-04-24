# guile-r7rs

[![builds.sr.ht status](https://builds.sr.ht/~amz3/guile-r7rs.svg)](https://builds.sr.ht/~amz3/guile-r7rs?)

## Introduction

guile-r7rs is the collection of libraries part of
[R7RS](https://r7rs.org) bundled for GNU Guile 2.2 or later.

### How to contribute

1. Create an account on [sr.ht](https://meta.sr.ht/register). To
   contribute to existing repository, it is free.

2. Pick an item and check nobody is working on it in the
   [todo](https://todo.sr.ht/~amz3/guile-r7rs).

3. Add documentation, tests or an implementation based on existing
   Guile modules or sample implementation that can be found at
   [http://srfi.schemers.org/](http://srfi.schemers.org/). Also, R7RS
   small is implemented in terms of R6RS in
   [akku-r7rs](https://gitlab.com/akkuscm/akku-r7rs/) in a compatible
   license.

4. When your contribution is ready, ask amirouche at hyper dev to
   become a contributor to be able to push.

Don't forget to add your name in the license header.

When you add a documentation file, don't forget to add it to
`DOCUMENTATION_FILES` inside the `Makefile`. To build the
documentation you will need `pandoc`, `latex` and to run `make doc`.

When you add a test file, don't forget to add it to `TESTS_FILES`
inside `Makefile`. To run the tests use `make check`.

### Table of Content

#### R7RS small

- `(scheme base)`
- `(scheme case-lambda)`
- `(scheme char)`
- `(scheme complex)`
- `(scheme cxr)`
- `(scheme eval)`
- `(scheme file)`
- `(scheme inexact)`
- `(scheme lazy)`
- `(scheme load)`
- `(scheme process-context)`
- `(scheme r5rs)`
- `(scheme read)`
- `(scheme repl)`
- `(scheme time)`
- `(scheme write)`

#### R7RS Red Edition

- `(scheme box)` aka. SRFI 111
- `(scheme charset)` aka. SRFI 14
- `(scheme comparator)` aka. SRFI 128
- `(scheme ephemeron)`) aka. SRFI 124
- `(scheme hash-table)` aka. SRFI 125
- `(scheme ideque)`) aka. SRFI 134
- `(scheme ilist)` aka. SRFI 116
- `(scheme list)` aka. SRFI 1
- `(scheme list-queue)` aka. SRFI 117
- `(scheme lseq)` aka. SRFI 127
- `(scheme rlist)` aka SRFI 101
- `(scheme set)` aka. SRFI 113
- `(scheme sort)` aka. SRFI 132
- `(scheme stream)` aka. SRFI 41
- `(scheme text)` aka. SRFI 135
- `(scheme vector)` aka. SRFI 133

#### R7RS Tangerine Edition

- `(scheme mapping)` aka. SRFI 146
- `(scheme mapping hash)` aka. SRFI 146
- `(scheme regex)` aka. SRFI 115
- `(scheme generator)` aka. SRFI 158
- `(scheme division)` aka. SRFI 141
- `(scheme bitwise)` aka. SRFI 151
- `(scheme fixnum)` aka. SRFI 143
- `(scheme flonum)` aka. SRFI 144
- `(scheme bytevector)` aka. `(rnrs bytevectors)` aka. SRFI 4
- `(scheme vector @)` aka. SRFI 160 where @ is any of base, u8, s8, u16, s16, u32, s32, u64, s64, f32, f64, c64, c128.
- `(scheme show)` aka. SRFI 159
