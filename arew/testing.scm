(define-module (arew testing))

(export test)
(export test-raise)

(import (rnrs))


(define-syntax-rule (test expected actual)
  (lambda ()
    (let ((expected* expected)
          (actual* actual))
      (if (equal? expected* actual*)
          (list #t)
          (list #f 'unexpected expected* actual*)))))


(define %does-not-raise (list 'does-not-raise))
(define %wrong-exception (list 'wrong-exception))
(define %good-exception (list 'good-exception))


(define-syntax-rule (test-raise predicate? thunk)
  (lambda ()
    (let ((out (guard (ex ((predicate? ex) %good-exception) (else %wrong-exception))
                 (thunk)
                 %does-not-raise)))
      (if (eq? out %good-exception)
          (list #t)
          (list #f 'raise-error predicate? out)))))
