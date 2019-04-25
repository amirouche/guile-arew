;;; Copyright (C) John Cowan (2015). All Rights Reserved.
;;;
;;; Permission is hereby granted, free of charge, to any person
;;; obtaining a copy of this software and associated documentation
;;; files (the "Software"), to deal in the Software without
;;; restriction, including without limitation the rights to use,
;;; copy, modify, merge, publish, distribute, sublicense, and/or
;;; sell copies of the Software, and to permit persons to whom the
;;; Software is furnished to do so, subject to the following
;;; conditions:
;;;
;;; The above copyright notice and this permission notice shall be
;;; included in all copies or substantial portions of the Software.
;;;
;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
;;; OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;;; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;;; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;;; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
;;; OTHER DEALINGS IN THE SOFTWARE.

;;
;; Comments:
;;
;; - Adapted to guile by Linus Björnstam
;; - Made part of guile-r7rs by Amirouche Boubekki
;;

(import (srfi srfi-64))
(import (scheme comparator))
(import (rnrs bytevectors)) ;; TODO: replace with (scheme bytevector)

(define-syntax test
  (syntax-rules ()
    ((_ args ...)
     (test-equal args ...))))

(define (print x) (display x) (newline))

(define (vector-cdr vec)
  (let* ((len (vector-length vec))
         (result (make-vector (- len 1))))
    (let loop ((n 1))
      (cond
       ((= n len) result)
       (else (vector-set! result (- n 1) (vector-ref vec n))
             (loop (+ n 1)))))))



  (define default-comparator (make-default-comparator))
  (define real-comparator (make-comparator real? = < number-hash))
  (define degenerate-comparator (make-comparator (lambda (x) #t) equal? #f #f))
  (define boolean-comparator
    (make-comparator boolean? eq? (lambda (x y) (and (not x) y)) boolean-hash))
  (define bool-pair-comparator (make-pair-comparator boolean-comparator boolean-comparator))
  (define num-list-comparator
    (make-list-comparator real-comparator list? null? car cdr))
  (define num-vector-comparator
    (make-vector-comparator real-comparator vector? vector-length vector-ref))
  (define vector-qua-list-comparator
    (make-list-comparator
      real-comparator
      vector?
      (lambda (vec) (= 0 (vector-length vec)))
      (lambda (vec) (vector-ref vec 0))
      vector-cdr))
  (define list-qua-vector-comparator
     (make-vector-comparator default-comparator list? length list-ref))
  (define eq-comparator (make-eq-comparator))
  (define eqv-comparator (make-eqv-comparator))
  (define equal-comparator (make-equal-comparator))
  (define symbol-comparator
    (make-comparator
      symbol?
      eq?

      (lambda (a b) (string<? (symbol->string a) (symbol->string b)))
      symbol-hash))

(define bool-pair (cons #t #f))
(define bool-pair-2 (cons #t #f))
(define reverse-bool-pair (cons #f #t))


(define x1 0)
(define x2 0)
(define x3 0)
(define x4 0)
(define ttp (lambda (x) (set! x1 111) #t))
(define eqp (lambda (x y) (set! x2 222) #t))
(define orp (lambda (x y) (set! x3 333) #t))
(define hf (lambda (x) (set! x4 444) 0))
(define comp (make-comparator ttp eqp orp hf))

(test-begin "comparator")
(test-group "comparators"
  (test '#(2 3 4) (vector-cdr '#(1 2 3 4)))
  (test '#() (vector-cdr '#(1)))

  (test-group "comparators/predicates"
    (test-assert (comparator? real-comparator))
    (test-assert (not (comparator? =)))
    (test-assert (comparator-ordered? real-comparator))
    (test-assert (comparator-hashable? real-comparator))
    (test-assert (not (comparator-ordered? degenerate-comparator)))
    (test-assert (not (comparator-hashable? degenerate-comparator)))
  ) ; end comparators/predicates

  (test-group "comparators/constructors"
    (test-assert (=? boolean-comparator #t #t))
    (test-assert (not (=? boolean-comparator #t #f)))
    (test-assert (<? boolean-comparator #f #t))
    (test-assert (not (<? boolean-comparator #t #t)))
    (test-assert (not (<? boolean-comparator #t #f)))

    (test-assert (comparator-test-type bool-pair-comparator '(#t . #f)))
    (test-assert (not (comparator-test-type bool-pair-comparator 32)))
    (test-assert (not (comparator-test-type bool-pair-comparator '(32 . #f))))
    (test-assert (not (comparator-test-type bool-pair-comparator '(#t . 32))))
    (test-assert (not (comparator-test-type bool-pair-comparator '(32 . 34))))
    (test-assert (=? bool-pair-comparator '(#t . #t) '(#t . #t)))
    (test-assert (not (=? bool-pair-comparator '(#t . #t) '(#f . #t))))
    (test-assert (not (=? bool-pair-comparator '(#t . #t) '(#t . #f))))
    (test-assert (<? bool-pair-comparator '(#f . #t) '(#t . #t)))
    (test-assert (<? bool-pair-comparator '(#t . #f) '(#t . #t)))
    (test-assert (not (<? bool-pair-comparator '(#t . #t) '(#t . #t))))
    (test-assert (not (<? bool-pair-comparator '(#t . #t) '(#f . #t))))
    (test-assert (not (<? bool-pair-comparator '(#f . #t) '(#f . #f))))

    (test-assert (comparator-test-type num-vector-comparator '#(1 2 3)))
    (test-assert (comparator-test-type num-vector-comparator '#()))
    (test-assert (not (comparator-test-type num-vector-comparator 1)))
    (test-assert (not (comparator-test-type num-vector-comparator '#(a 2 3))))
    (test-assert (not (comparator-test-type num-vector-comparator '#(1 b 3))))
    (test-assert (not (comparator-test-type num-vector-comparator '#(1 2 c))))
    (test-assert (=? num-vector-comparator '#(1 2 3) '#(1 2 3)))
    (test-assert (not (=? num-vector-comparator '#(1 2 3) '#(4 5 6))))
    (test-assert (not (=? num-vector-comparator '#(1 2 3) '#(1 5 6))))
    (test-assert (not (=? num-vector-comparator '#(1 2 3) '#(1 2 6))))
    (test-assert (<? num-vector-comparator '#(1 2) '#(1 2 3)))
    (test-assert (<? num-vector-comparator '#(1 2 3) '#(2 3 4)))
    (test-assert (<? num-vector-comparator '#(1 2 3) '#(1 3 4)))
    (test-assert (<? num-vector-comparator '#(1 2 3) '#(1 2 4)))
    (test-assert (<? num-vector-comparator '#(3 4) '#(1 2 3)))
    (test-assert (not (<? num-vector-comparator '#(1 2 3) '#(1 2 3))))
    (test-assert (not (<? num-vector-comparator '#(1 2 3) '#(1 2))))
    (test-assert (not (<? num-vector-comparator '#(1 2 3) '#(0 2 3))))
    (test-assert (not (<? num-vector-comparator '#(1 2 3) '#(1 1 3))))

    (test-assert (not (<? vector-qua-list-comparator '#(3 4) '#(1 2 3))))
    (test-assert (<? list-qua-vector-comparator '(3 4) '(1 2 3)))


    (test-assert (=? eq-comparator #t #t))
    (test-assert (not (=? eq-comparator #f #t)))
    (test-assert (=? eqv-comparator bool-pair bool-pair))
    (test-assert (not (=? eqv-comparator bool-pair bool-pair-2)))
    (test-assert (=? equal-comparator bool-pair bool-pair-2))
    (test-assert (not (=? equal-comparator bool-pair reverse-bool-pair)))
  ) ; end comparators/constructors

  (test-group "comparators/hash"
    (test-assert (exact-integer? (boolean-hash #f)))
    (test-assert (not (negative? (boolean-hash #t))))
    (test-assert (exact-integer? (char-hash #\a)))
    (test-assert (not (negative? (char-hash #\b))))
    (test-assert (exact-integer? (char-ci-hash #\a)))
    (test-assert (not (negative? (char-ci-hash #\b))))
    (test-assert (= (char-ci-hash #\a) (char-ci-hash #\A)))
    (test-assert (exact-integer? (string-hash "f")))
    (test-assert (not (negative? (string-hash "g"))))
    (test-assert (exact-integer? (string-ci-hash "f")))
    (test-assert (not (negative? (string-ci-hash "g"))))
    (test-assert (= (string-ci-hash "f") (string-ci-hash "F")))
    (test-assert (exact-integer? (symbol-hash 'f)))
    (test-assert (not (negative? (symbol-hash 't))))
    (test-assert (exact-integer? (number-hash 3)))
    (test-assert (not (negative? (number-hash 3))))
    (test-assert (exact-integer? (number-hash -3)))
    (test-assert (not (negative? (number-hash -3))))
    (test-assert (exact-integer? (number-hash 3.0)))
    (test-assert (not (negative? (number-hash 3.0))))
    (test-assert (exact-integer? (number-hash 3.47)))
    (test-assert (not (negative? (number-hash 3.47))))
    (test-assert (exact-integer? (default-hash '())))
    (test-assert (not (negative? (default-hash '()))))
    (test-assert (exact-integer? (default-hash '(a "b" #\c #(dee) 2.718))))
    (test-assert (not (negative? (default-hash '(a "b" #\c #(dee) 2.718)))))
    (test-assert (exact-integer? (default-hash '#u8())))
    (test-assert (not (negative? (default-hash '#u8()))))
    (test-assert (exact-integer? (default-hash '#u8(8 6 3))))
    (test-assert (not (negative? (default-hash '#u8(8 6 3)))))
    (test-assert (exact-integer? (default-hash '#())))
    (test-assert (not (negative? (default-hash '#()))))
    (test-assert (exact-integer? (default-hash '#(a "b" #\c #(dee) 2.718))))
    (test-assert (not (negative? (default-hash '#(a "b" #\c #(dee) 2.718)))))

  ) ; end comparators/hash

  (test-group "comparators/default"
    (test-assert (<? default-comparator '() '(a)))
    (test-assert (not (=? default-comparator '() '(a))))
    (test-assert (=? default-comparator #t #t))
    (test-assert (not (=? default-comparator #t #f)))
    (test-assert (<? default-comparator #f #t))
    (test-assert (not (<? default-comparator #t #t)))
    (test-assert (=? default-comparator #\a #\a))
    (test-assert (<? default-comparator #\a #\b))

    (test-assert (comparator-test-type default-comparator '()))
    (test-assert (comparator-test-type default-comparator #t))
    (test-assert (comparator-test-type default-comparator #\t))
    (test-assert (comparator-test-type default-comparator '(a)))
    (test-assert (comparator-test-type default-comparator 'a))
    (test-assert (comparator-test-type default-comparator (make-bytevector 10)))
    (test-assert (comparator-test-type default-comparator 10))
    (test-assert (comparator-test-type default-comparator 10.0))
    (test-assert (comparator-test-type default-comparator "10.0"))
    (test-assert (comparator-test-type default-comparator '#(10)))

    (test-assert (=? default-comparator '(#t . #t) '(#t . #t)))
    (test-assert (not (=? default-comparator '(#t . #t) '(#f . #t))))
    (test-assert (not (=? default-comparator '(#t . #t) '(#t . #f))))
    (test-assert (<? default-comparator '(#f . #t) '(#t . #t)))
    (test-assert (<? default-comparator '(#t . #f) '(#t . #t)))
    (test-assert (not (<? default-comparator '(#t . #t) '(#t . #t))))
    (test-assert (not (<? default-comparator '(#t . #t) '(#f . #t))))
    (test-assert (not (<? default-comparator '#(#f #t) '#(#f #f))))

    (test-assert (=? default-comparator '#(#t #t) '#(#t #t)))
    (test-assert (not (=? default-comparator '#(#t #t) '#(#f #t))))
    (test-assert (not (=? default-comparator '#(#t #t) '#(#t #f))))
    (test-assert (<? default-comparator '#(#f #t) '#(#t #t)))
    (test-assert (<? default-comparator '#(#t #f) '#(#t #t)))
    (test-assert (not (<? default-comparator '#(#t #t) '#(#t #t))))
    (test-assert (not (<? default-comparator '#(#t #t) '#(#f #t))))
    (test-assert (not (<? default-comparator '#(#f #t) '#(#f #f))))

    (test-assert (= (comparator-hash default-comparator #t) (boolean-hash #t)))
    (test-assert (= (comparator-hash default-comparator #\t) (char-hash #\t)))
    (test-assert (= (comparator-hash default-comparator "t") (string-hash "t")))
    (test-assert (= (comparator-hash default-comparator 't) (symbol-hash 't)))
    (test-assert (= (comparator-hash default-comparator 10) (number-hash 10)))
    (test-assert (= (comparator-hash default-comparator 10.0) (number-hash 10.0)))

    (comparator-register-default!
      (make-comparator procedure? (lambda (a b) #t) (lambda (a b) #f) (lambda (obj) 200)))
    (test-assert (=? default-comparator (lambda () #t) (lambda () #f)))
    (test-assert (not (<? default-comparator (lambda () #t) (lambda () #f))))
    (test 200 (comparator-hash default-comparator (lambda () #t)))

  )

  (test-group "comparators/accessors"

    (test #t (and ((comparator-type-test-predicate comp) x1)   (= x1 111)))
    (test #t (and ((comparator-equality-predicate comp) x1 x2) (= x2 222)))
    (test #t (and ((comparator-ordering-predicate comp) x1 x3) (= x3 333)))
    (test #t (and (zero? ((comparator-hash-function comp) x1)) (= x4 444)))
  ) ; end comparators/accessors

  (test-group "comparators/invokers"
    (test-assert (comparator-test-type real-comparator 3))
    (test-assert (comparator-test-type real-comparator 3.0))
    (test-assert (not (comparator-test-type real-comparator "3.0")))
    (test-assert (comparator-check-type boolean-comparator #t))
    (test-error (comparator-check-type boolean-comparator 't))
  ) ; end comparators/invokers

  (test-group "comparators/comparison"
    (test-assert (=? real-comparator 2 2.0 2))
    (test-assert (<? real-comparator 2 3.0 4))
    (test-assert (>? real-comparator 4.0 3.0 2))
    (test-assert (<=? real-comparator 2.0 2 3.0))
    (test-assert (>=? real-comparator 3 3.0 2))
    (test-assert (not (=? real-comparator 1 2 3)))
    (test-assert (not (<? real-comparator 3 1 2)))
    (test-assert (not (>? real-comparator 1 2 3)))
    (test-assert (not (<=? real-comparator 4 3 3)))
    (test-assert (not (>=? real-comparator 3 4 4.0)))

  ) ; end comparators/comparison

  (test-group "comparators/syntax"
    (test 'less (comparator-if<=> real-comparator 1 2 'less 'equal 'greater))
    (test 'equal (comparator-if<=> real-comparator 1 1 'less 'equal 'greater))
    (test 'greater (comparator-if<=> real-comparator 2 1 'less 'equal 'greater))
    (test 'less (comparator-if<=> "1" "2" 'less 'equal 'greater))
    (test 'equal (comparator-if<=> "1" "1" 'less 'equal 'greater))
    (test 'greater (comparator-if<=> "2" "1" 'less 'equal 'greater))

  ) ; end comparators/syntax

  (test-group "comparators/bound-salt"
    (test-assert (exact-integer? (hash-bound)))
    (test-assert (exact-integer? (hash-salt)))
    (test-assert (< (hash-salt) (hash-bound)))
#;  (test (hash-salt) (fake-salt-hash #t))  ; no such thing as fake-salt-hash
  ) ; end comparators/bound-salt

) ; end comparators

(test-end "comparator")

;; exit
(define xpass (test-runner-xpass-count (test-runner-current)))
(define fail (test-runner-fail-count (test-runner-current)))
(if (and (= xpass 0) (= fail 0))
    (exit 0)
    (exit 1))
