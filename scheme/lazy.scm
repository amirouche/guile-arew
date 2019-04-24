;; -*- mode: scheme; coding: utf-8 -*-
;; SPDX-License-Identifier: CC0-1.0
#!r6rs

(define-module (scheme lazy))

(import
 (rnrs)
 (srfi srfi-45))

(re-export delay force)
(re-export (eager . make-promise)
           (lazy . delay-force))
(export promise?)

;; Uses the fact that chez-srfi promises are based on records.
(define (promise? x)
  (and (record? x)
       (eq? (record-rtd x)
            (record-rtd (eager #f))))))
