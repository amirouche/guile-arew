(import (srfi srfi-64))
(import (scheme base))
(import (scheme r5rs))


(test-begin "r5rs")

(test-end)


(define xpass (test-runner-xpass-count (test-runner-current)))
(define fail (test-runner-fail-count (test-runner-current)))
(if (and (= xpass 0) (= fail 0))
    (exit 0)
    (exit 1))
