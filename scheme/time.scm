;; -*- mode: scheme; coding: utf-8 -*-
;; SPDX-License-Identifier: CC0-1.0
#!r6rs

(define-module (scheme time))

(import
 (rnrs)
 (srfi srfi-19))

(export current-jiffy current-second jiffies-per-second)

(define scale 1000000000.0)

(define (jiffies-per-second)
  (exact scale))

(define (current-jiffy)
  (exact (return-sec time-monotonic)))

(define (current-second)
  (return-sec time-tai))

(define (return-sec sym)
  (let ((t (current-time sym)))
    (+ (* scale (time-second t))
       (time-nanosecond t))))
