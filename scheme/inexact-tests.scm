(import (srfi srfi-64))
(import (scheme base))
(import (scheme cxr))


(test-begin "inexact")

(test-end)


(define xpass (test-runner-xpass-count (test-runner-current)))
(define fail (test-runner-fail-count (test-runner-current)))
(if (and (= xpass 0) (= fail 0))
    (exit 0)
    (exit 1))
