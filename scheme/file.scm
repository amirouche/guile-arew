;; -*- mode: scheme; coding: utf-8 -*-
;; SPDX-License-Identifier: CC0-1.0
#!r6rs

(define-module (scheme file))

(import (rnrs))

(re-export
 call-with-input-file call-with-output-file delete-file file-exists?
 open-input-file open-output-file with-input-from-file
 with-output-to-file)

(export open-binary-input-file)
(export open-binary-output-file)

(define (open-binary-input-file file)
  (open-file-input-port file))

(define (open-binary-output-file file)
  (open-file-output-port file)))
