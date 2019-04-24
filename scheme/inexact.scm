;; -*- mode: scheme; coding: utf-8 -*-
;; SPDX-License-Identifier: CC0-1.0
#!r6rs

(define-module (scheme inexact))

(import
 (except (rnrs) finite? infinite? nan?)
 (prefix (rnrs) r6:))

(re-export acos asin atan cos exp log sin sqrt tan)
(export finite? infinite? nan?)


(define (finite? z)
  (if (complex? z)
      (and (r6:finite? (real-part z))
           (r6:finite? (imag-part z)))
      (r6:finite? z)))

(define (infinite? z)
  (if (complex? z)
      (or (r6:infinite? (real-part z))
          (r6:infinite? (imag-part z)))
      (r6:infinite? z)))

(define (nan? z)
  (if (complex? z)
      (or (r6:nan? (real-part z))
          (r6:nan? (imag-part z)))
      (r6:nan? z))))
