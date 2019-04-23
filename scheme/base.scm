;;
;;      Copyright (C) 2019 amirouche@hyper.dev
;;
;; This library is free software; you can redistribute it and/or
;; modify it under the terms of the GNU Lesser General Public
;; License as published by the Free Software Foundation; either
;; version 3 of the License, or (at your option) any later version.
;;
;; This library is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; Lesser General Public License for more details.
;;
;; You should have received a copy of the GNU Lesser General Public
;; License along with this library; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

;;
;; Based on akku-r7rs.
;;
;; TODO: cond-expand, features, include-ci Also there is no such
;; things as binary-ports and textual-port? in guile, a port can be
;; binary or textual. See other TODO in this file.
;;
(define-module (scheme base))

(import
 (except (rnrs) case syntax-rules error define-record-type
         string->list string-copy string->utf8 vector->list
         vector-fill! bytevector-copy! bytevector-copy
         utf8->string
         map for-each member assoc
         vector-map read
         let-syntax
         expt)
 (prefix (rnrs) r6:)
 (only (rnrs bytevectors) u8-list->bytevector)
 (only (rnrs control) case-lambda)
 (rnrs conditions)
 (rnrs io ports)
 (rnrs mutable-pairs)
 (prefix (rnrs mutable-strings) r6:)
 (only (rnrs mutable-strings) string-set!)
 (rnrs syntax-case)
 (rnrs r5rs)
 (only (srfi srfi-1) map for-each member assoc make-list list-copy)
 (srfi srfi-6)
 (prefix (srfi srfi-9) srfi-9:)
 (only (srfi srfi-13) string-copy!)
 (prefix (srfi srfi-39) srfi-39:)
 (prefix (only (srfi srfi-43) vector-copy!) srfi-43:))

(re-export
 * + - / < <= = > >= abs and append apply assoc assq assv begin
 caar cadr
 call-with-current-continuation call-with-values
 call/cc car cdar cddr cdr ceiling char->integer char-ready?
 char<=? char<? char=? char>=? char>? char? close-input-port
 close-output-port close-port complex? cond cond-expand cons
 current-error-port current-input-port current-output-port define
 define-syntax define-values denominator do
 dynamic-wind eof-object? eq? equal? eqv?
 even?
 exact-integer-sqrt exact-integer? exact? expt
 floor floor-quotient floor-remainder floor/
 for-each gcd
 get-output-string if include inexact?
 input-port? integer->char integer? lambda lcm
 length let let* letrec letrec*
 letrec-syntax list list->string list->vector list-copy list-ref
 list-set! list-tail list? make-list make-parameter
 make-string make-vector map max member memq memv min modulo
 negative? newline not null? number->string number? numerator odd?
 open-input-string
 open-output-string or output-port? pair?
 parameterize peek-char port? positive? procedure?
 quasiquote quote quotient raise rational?
 rationalize read-char
 real? remainder reverse round set!
 set-car! set-cdr! string string->list string->number
 string->symbol symbol string-append
 string-copy string-copy! string-fill! string-for-each
 string-length string-map string-ref string-set! string<=? string<?
 string=? string>=? string>? string? substring symbol->string
 symbol? truncate
 truncate-quotient truncate-remainder truncate/ unless
 unquote unquote-splicing values vector vector->list
 vector-copy vector-fill!
 vector-length vector-ref vector-set!
 vector? when write-char
 zero?)

(export! error)
(export syntax-error let-syntax syntax-rules bytevector
        bytevector-append bytevector-copy bytevector-copy!
        bytevector-length bytevector-u8-ref bytevector-u8-set!
        error-object-irritants error-object-message error-object?
        file-error? flush-output-port get-output-bytevector
        open-input-bytevector open-output-bytevector peek-u8
        read-bytevector read-bytevector! read-error? read-line
        read-string read-u8 square string->utf8 string->vector
        utf8->string vector->string vector-append write-bytevector
        write-string write-u8)

(re-export (r6:boolean=? . boolean=?))
(re-export (r6:bytevector? . bytevector?))
(re-export (r6:call-with-port . call-with-port))
(re-export (srfi-9:define-record-type . define-record-type))
(re-export (r6:eof-object . eof-object))
(re-export (r6:exact . exact))
(re-export (r6:guard . guard))
(re-export (r6:inexact . inexact))
;; TODO: (re-export (r6:input-port-open? . input-port-open?))
(re-export (r6:let*-values . let*-values))
(re-export (r6:let-values . let-values))
(re-export (r6:make-bytevector . make-bytevector))
;; TODO: (re-export (r6:output-port-open? . output-port-open?))
(re-export (r6:raise-continuable . raise-continuable))
(re-export (r6:symbol=? . symbol=?))
;; TODO: (re-export (r6:u8-ready? . u8-ready?))
(re-export (srfi-43:vector-copy! . vector-copy!))
(re-export (r6:vector-for-each . vector-for-each))
(re-export (r6:vector-map . vector-map))
(re-export (r6:with-exception-handler . with-exception-handler))
(re-export (r6:case . case))


(define (error message . irritants)
  (if (and (symbol? message) (pair? irritants) (string? (car irritants)))
      (apply r6:error message irritants)
      (apply r6:error #f message irritants)))


(define-syntax syntax-error
  (lambda (x)
    (syntax-case x ()
      ((_ message args ...)
       (syntax-violation 'syntax-error #'message '#'(args ...))))))

;; let-syntax from Kato2014.
(define-syntax let-syntax
  (lambda (x)
    (syntax-case x ()
      ((_ ((vars trans) ...) . expr)
       #'(r6:let-syntax ((vars trans) ...)
                        (let () . expr))))))

;;; SRFI-46 style syntax-rules

;; FIXME: We should use with-syntax like:
;;   http://srfi.schemers.org/srfi-93/mail-archive/msg00024.html
(define-syntax syntax-rules
  (lambda (x)
    ;; filt and emap handle ellipsis in the patterns
    (define (filt elip x)
      (if (identifier? x)
          (cond ((free-identifier=? elip x) #'(... ...))
                ((free-identifier=? #'(... ...) x) #'bogus)
                (else x))
          x))
    (define (emap elip in)
      (syntax-case in ()
        ((x . y) (cons (emap elip #'x)
                       (emap elip #'y)))
        (#(x ...) (list->vector (emap elip #'(x ...))))
        (x (filt elip #'x))))
    ;; This translates _ into temporaries and guards -weinholt
    (define (get-underscores stx)
      (syntax-case stx ()
        [(x . y)
         (let-values (((t0 p0) (get-underscores #'x))
                      ((t1 p1) (get-underscores #'y)))
           (values (append t0 t1) (cons p0 p1)))]
        [#(x* ...)
         (let lp ((x* #'(x* ...))
                  (t* '())
                  (p* '()))
           (if (null? x*)
               (values (apply append (reverse t*))
                       (list->vector (reverse p*)))
               (let-values (((t p) (get-underscores (car x*))))
                 (lp (cdr x*) (cons t t*) (cons p p*)))))]
        [x
         (and (identifier? #'x) (free-identifier=? #'x #'_))
         (let ((t* (generate-temporaries #'(_))))
           (values t* (car t*)))]
        [x
         (values '() #'x)]))
    (syntax-case x ()
      ((_ (lit ...) (pat tmpl) ...)     ;compatible with r6rs
       (not (memq '_ (syntax->datum #'(lit ...))))
       #'(r6:syntax-rules (lit ...) (pat tmpl) ...))

      ((_ (lit ...) (pat tmpl) ...)     ;_ in the literals list
       #'(syntax-rules (... ...) (lit ...) (pat tmpl) ...))

      ((_ elip (lit ...) (pat tmpl) ...)  ;custom ellipsis
       (and (identifier? #'elip)
            (not (memq '_ (syntax->datum #'(lit ...)))))
       (with-syntax (((clause ...) (emap #'elip #'((pat tmpl) ...))))
         #'(r6:syntax-rules (lit ...) clause ...)))

      ((_ elip (lit ...) (pat tmpl) ...)
       ;; Both custom ellipsis and _ in the literals list.
       (identifier? #'elip)
       (with-syntax (((clause ...) (emap #'elip #'((pat tmpl) ...)))
                     ((lit^ ...) (filter (lambda (x)
                                           (not (free-identifier=? #'_ x)))
                                         #'(lit ...))))
         (with-syntax (((clause^ ...)
                        (map (lambda (cls)
                               (syntax-case cls ()
                                 [((_unused . pattern) template)
                                  (let-values (((t p) (get-underscores #'pattern)))
                                    (if (null? t)
                                        #'((_unused . pattern)
                                           #'template)
                                        (with-syntax ((pattern^ p) ((t ...) t))
                                          #'((_unused . pattern^)
                                             (and (underscore? #'t) ...)
                                             #'template))))]))
                             #'(clause ...))))
           #'(lambda (y)
               (define (underscore? x)
                 (and (identifier? x) (free-identifier=? x #'_)))
               (syntax-case y (lit^ ...)
                 clause^ ...))))))))

;;; Case

(define-syntax %r7case-clause
  (syntax-rules (else =>)
    ((_ obj (translated ...) ())
     (r6:case obj translated ...))
    ((_ obj (translated ...) (((e0 e1 ...) => f) rest ...))
     (%r7case-clause obj (translated ... ((e0 e1 ...) (f obj))) (rest ...)))
    ((_ obj (translated ...) ((else => f) rest ...))
     (%r7case-clause obj (translated ... (else (f obj))) (rest ...)))
    ((_ obj (translated ...) (otherwise rest ...))
     (%r7case-clause obj (translated ... otherwise) (rest ...)))))

(define-syntax case
  (syntax-rules (else =>)
    ((_ key clause ...)
     (let ((obj key))
       (%r7case-clause obj () (clause ...))))))

;;;

;; R7RS error object will be mapped to R6RS condition object
(define error-object? condition?)
(define file-error? i/o-error?)
(define read-error? lexical-violation?)

(define (error-object-irritants obj)
  (and (irritants-condition? obj)
       (condition-irritants obj)))

(define (error-object-message obj)
  (and (message-condition? obj)
       (condition-message obj)))

;;; Ports

(define (open-input-bytevector bv) (open-bytevector-input-port bv))

(define (open-output-bytevector)
  (let-values (((p extract) (open-bytevector-output-port)))
    (define pos 0)
    (define buf #vu8())
    (define (read! target target-start count)
      (when (zero? (- (bytevector-length buf) pos))
        (set! buf (bytevector-append buf (extract))))  ;resets p
      (let ((count (min count (- (bytevector-length buf) pos))))
        (r6:bytevector-copy! buf pos
                             target target-start count)
        (set! pos (+ pos count))
        count))
    (define (write! bv start count)
      (put-bytevector p bv start count)
      (set! pos (+ pos count))
      count)
    (define (get-position)
      pos)
    (define (set-position! new-pos)
      (set! pos new-pos))
    (define (close)
      (close-port p))
    ;; It's actually an input/output port, but only
    ;; get-output-bytevector should ever read from it. If it was just
    ;; an output port then there would be no good way for
    ;; get-output-bytevector to read the data. -weinholt
    (make-custom-binary-input/output-port
     "bytevector" read! write! get-position set-position! close)))

(define (get-output-bytevector port)
  ;; R7RS says "It is an error if port was not created with
  ;; open-output-bytevector.", so we can safely assume that the port
  ;; was created by open-output-bytevector. -weinholt
  (set-port-position! port 0)
  (let ((bv (get-bytevector-all port)))
    (if (eof-object? bv)
        #vu8()
        bv)))

(define (exact-integer? i) (and (integer? i) (exact? i)))

(define peek-u8
  (case-lambda
    (() (peek-u8 (current-input-port)))
    ((port)
     (lookahead-u8 port))))

(define read-bytevector
  (case-lambda
    ((len) (read-bytevector len (current-input-port)))
    ((len port) (get-bytevector-n port len))))

(define read-string
  (case-lambda
    ((len) (read-string len (current-input-port)))
    ((len port) (get-string-n port len))))

(define read-bytevector!
  (case-lambda
    ((bv)
     (read-bytevector! bv (current-input-port)))
    ((bv port)
     (read-bytevector! bv port 0))
    ((bv port start)
     (read-bytevector! bv port start (bytevector-length bv)))
    ((bv port start end)
     (get-bytevector-n! port bv start (- end start)))))

(define read-line
  (case-lambda
    (() (read-line (current-input-port)))
    ((port) (get-line port))))

(define write-u8
  (case-lambda
    ((obj) (write-u8 obj (current-output-port)))
    ((obj port) (put-u8 port obj))))

(define read-u8
  (case-lambda
    (() (read-u8 (current-input-port)))
    ((port) (get-u8 port))))

(define write-bytevector
  (case-lambda
    ((bv) (write-bytevector bv (current-output-port)))
    ((bv port) (put-bytevector port bv))
    ((bv port start) (write-bytevector (%subbytevector1 bv start) port))
    ((bv port start end)
     (write-bytevector (%subbytevector bv start end) port))))

(define write-string
  (case-lambda
    ((str) (write-string str (current-output-port)))
    ((str port) (put-string port str))
    ((str port start) (write-string str port start (string-length str)))
    ((str port start end)
     (write-string (substring str start end) port))))


;;; List additions

(define (list-set! l k obj)
  (define (itr cur count)
    (if (= count k)
        (set-car! cur obj)
        (itr (cdr cur) (+ count 1))))
  (itr l 0))

;;; Vector and string additions

;; FIXME: Optimize them
(define (string-map proc . strs)
  (list->string (apply map proc (map r6:string->list strs))))

(define (vector-map proc . args)
  (list->vector (apply map proc (map r6:vector->list args))))

(define (bytevector . lis)
  (u8-list->bytevector lis))

(define (bytevector-append . bvs)
  (call-with-bytevector-output-port
   (lambda (p)
     (for-each (lambda (bv) (put-bytevector p bv)) bvs))))

(define (vector-append . lis)
  (list->vector (apply append (map r6:vector->list lis))))

;;; Substring functionalities added

;; string
(define (%substring1 str start) (substring str start (string-length str)))

(define string->list
  (case-lambda
    ((str) (r6:string->list str))
    ((str start) (r6:string->list (%substring1 str start)))
    ((str start end) (r6:string->list (substring str start end)))))

(define string->vector
  (case-lambda
    ((str) (list->vector (string->list str)))
    ((str start) (string->vector (%substring1 str start)))
    ((str start end) (string->vector (substring str start end)))))

(define string-copy
  (case-lambda
    ((str) (r6:string-copy str))
    ((str start) (%substring1 str start))
    ((str start end) (substring str start end))))

(define string->utf8
  (case-lambda
    ((str) (r6:string->utf8 str))
    ((str start) (r6:string->utf8 (%substring1 str start)))
    ((str start end) (r6:string->utf8 (substring str start end)))))

(define string-fill!
  (case-lambda
    ((str fill) (r6:string-fill! str fill))
    ((str fill start) (string-fill! str fill start (string-length str)))
    ((str fill start end)
     (define (itr r)
       (unless (= r end)
         (string-set! str r fill)
         (itr (+ r 1))))
     (itr start))))

;;; vector

(define (%subvector v start end)
  (define mlen (- end start))
  (define out (make-vector (- end start)))
  (define (itr r)
    (if (= r mlen)
        out
        (begin
          (vector-set! out r (vector-ref v (+ start r)))
          (itr (+ r 1)))))
  (itr 0))

(define (%subvector1 v start) (%subvector v start (vector-length v)))

(define vector-copy
  (case-lambda
    ((v) (%subvector1 v 0))
    ((v start) (%subvector1 v start))
    ((v start end) (%subvector v start end))))

(define vector->list
  (case-lambda
    ((v) (r6:vector->list v))
    ((v start) (r6:vector->list (%subvector1 v start)))
    ((v start end) (r6:vector->list (%subvector v start end)))))

(define vector->string
  (case-lambda
    ((v) (list->string (vector->list v)))
    ((v start) (vector->string (%subvector1 v start)))
    ((v start end) (vector->string (%subvector v start end)))))

(define vector-fill!
  (case-lambda
    ((vec fill) (r6:vector-fill! vec fill))
    ((vec fill start) (vector-fill! vec fill start (vector-length vec)))
    ((vec fill start end)
     (define (itr r)
       (unless (= r end)
         (vector-set! vec r fill)
         (itr (+ r 1))))
     (itr start))))

(define (%subbytevector bv start end)
  (define mlen (- end start))
  (define out (make-bytevector mlen))
  (r6:bytevector-copy! bv start out 0 mlen)
  out)

(define (%subbytevector1 bv start)
  (%subbytevector bv start (bytevector-length bv)))

(define bytevector-copy!
  (case-lambda
    ((to at from) (bytevector-copy! to at from 0))
    ((to at from start)
     (let ((flen (bytevector-length from))
           (tlen (bytevector-length to)))
       (let ((fmaxcopysize (- flen start))
             (tmaxcopysize (- tlen at)))
         (bytevector-copy! to at from start (+ start
                                               (min fmaxcopysize
                                                    tmaxcopysize))))))
    ((to at from start end)
     (r6:bytevector-copy! from start to at (- end start)))))

(define bytevector-copy
  (case-lambda
    ((bv) (r6:bytevector-copy bv))
    ((bv start) (%subbytevector1 bv start))
    ((bv start end) (%subbytevector bv start end))))

(define utf8->string
  (case-lambda
    ((bv) (r6:utf8->string bv))
    ((bv start) (r6:utf8->string (%subbytevector1 bv start)))
    ((bv start end) (r6:utf8->string (%subbytevector bv start end)))))

;;; From division library

(define-syntax %define-division
  (syntax-rules ()
    ((_ fix quo rem q+r)
     (begin
       (define (quo x y)
         (exact (fix (/ x y))))
       (define (rem x y)
         (- x (* (quo x y) y)))
       (define (q+r x y)
         (let ((q (quo x y)))
           (values q
                   (- x (* q y)))))))))

(%define-division
 floor
 floor-quotient
 floor-remainder0 ;; Most implementation has native modulo
 floor/)
(define floor-remainder modulo)

(define truncate-quotient quotient)
(define truncate-remainder remainder)
(define (truncate/ x y)
  (values (truncate-quotient x y)
          (truncate-remainder x y)))

(define (square x) (* x x))

(define (expt x y)
  (if (eqv? x 0.0)
      (inexact (r6:expt x y))
      (r6:expt x y)))
