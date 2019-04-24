;; -*- mode: scheme; coding: utf-8 -*-
;; Copyright © 2018 Göran Weinholt <goran@weinholt.se>
;; SPDX-License-Identifier: CC0-1.0
#!r6rs

;; TODO: Get a writer that outputs with R7RS syntax.

(define-module (scheme write))

(import
 (rnrs)
 (srfi srfi-38))

(re-export
 display write
 (write-with-shared-structure . write-shared)
 (write . write-simple))      ;TODO: not correct
