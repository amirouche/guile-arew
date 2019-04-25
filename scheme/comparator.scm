;; Linus Björnstam disclaim all copyright for this file and release it
;; into the public domain In jurisdictions where that is not possible
;; you may use this file under CC0 but be aware that all the other
;; code in this repository is copyrighted by John Cowan and has been
;; released under the SRFI licence.

(define-module (scheme comparator))

(export comparator?
        comparator-ordered?
        comparator-hashable?
        make-comparator
        make-pair-comparator
        make-list-comparator
        make-vector-comparator
        make-eq-comparator
        make-eqv-comparator
        make-equal-comparator

        boolean-hash
        char-hash
        char-ci-hash
        string-hash
        string-ci-hash
        symbol-hash
        number-hash

        make-default-comparator
        default-hash
        comparator-register-default!
        comparator-type-test-predicate
        comparator-equality-predicate
        comparator-ordering-predicate
        comparator-hash-function
        comparator-test-type
        comparator-check-type
        comparator-hash
        hash-bound
        hash-salt

        =?
        <?
        >?
        <=?
        >=?
        comparator-if<=>)

(export! string-hash
         string-ci-hash
         symbol-hash)

(import (only (rnrs hashtables) equal-hash))
(import (only (rnrs unicode) char-foldcase string-foldcase))
(import (only (rnrs base) symbol=? exact infinite?))
(import (rnrs bytevectors))
(import (srfi srfi-9))

(define (boolean=? arg . args)
  (if (not (boolean? arg))
      #f
      (let loop ((prev arg) (args args))
        (cond
         ((null? args) #t)
         ((eq? prev (car args)) (loop (car args) (cdr args)))
         (else #f)))))

;; THESE FILES ARE LICENSED UNDER THE SRFI LICENSE
(include "comparator/body1.scm")
(include "comparator/body2.scm")
