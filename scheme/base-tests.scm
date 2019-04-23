(import (srfi srfi-64))
(import (scheme base))


(test-begin "scheme base")

(test-assert "+" (+ 1 2 3 4))

(guard (ex ((eq? ex 'foo) 'bar) ((eq? ex 'bar) 'baz))
  (raise 'bar))

(test-assert "error"
  (guard (ex ((string=? (error-object-message ex) "nok")))
    (error 'tests-raise "nok" 'climate-change)))

(test-assert "error"
  (guard (ex ((string=? (error-object-message ex) "nok")))
    (error "nok" 'climate-change)))

(test-end)
