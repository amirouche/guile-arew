(define-module (scheme mapping hash))

(import (scheme base)
        (srfi srfi-8)
        (scheme case-lambda)
        (scheme list)
        (scheme comparator)
        (scheme assume)
        (pfds hamts))

(export hashmap hashmap-unfold
        hashmap? hashmap-contains? hashmap-empty? hashmap-disjoint?
        hashmap-ref hashmap-ref/default hashmap-key-comparator
        hashmap-adjoin hashmap-adjoin!
        hashmap-set hashmap-set!
        hashmap-replace hashmap-replace!
        hashmap-delete hashmap-delete! hashmap-delete-all hashmap-delete-all!
        hashmap-intern hashmap-intern!
        hashmap-update hashmap-update! hashmap-update/default hashmap-update!/default
        hashmap-pop hashmap-pop!
        hashmap-search hashmap-search!
        hashmap-size hashmap-find hashmap-count hashmap-any? hashmap-every?
        hashmap-keys hashmap-values hashmap-entries
        hashmap-map hashmap-map->list hashmap-for-each hashmap-fold
        hashmap-filter hashmap-filter!
        hashmap-remove hashmap-remove!
        hashmap-partition hashmap-partition!
        hashmap-copy hashmap->alist alist->hashmap alist->hashmap!
        hashmap=? hashmap<? hashmap>? hashmap<=? hashmap>=?
        hashmap-union hashmap-intersection hashmap-difference hashmap-xor
        hashmap-union! hashmap-intersection! hashmap-difference! hashmap-xor!
        make-hashmap-comparator
        hashmap-comparator)

(re-export comparator?)


(define-record-type <hashmap>
  (make-hashmap comparator hamt)
  hashmap?
  (comparator hashmap-key-comparator)
  (hamt hashmap-hamt))

(define (make-empty-hashmap comparator)
  (let ((hash (comparator-hash-function comparator))
        (eqv? (comparator-equality-predicate comparator)))
    (make-hashmap comparator (make-hamt hash eqv?))))

(define singleton (list 'singleton))

;;; Exported procedures

;; Constructors

(define (hashmap comparator . args)
  (assume (comparator? comparator))
  (hashmap-unfold null?
                  (lambda (args)
                    (values (car args)
                            (cadr args)))
                  cddr
                  args
                  comparator))

(define (hashmap-unfold stop? mapper successor seed comparator)
  (assume (procedure? stop?))
  (assume (procedure? mapper))
  (assume (procedure? successor))
  (assume (comparator? comparator))
  (let loop ((hashmap (make-empty-hashmap comparator))
	     (seed seed))
    (if (stop? seed)
	hashmap
	(receive (key value)
	    (mapper seed)
	  (loop (hashmap-adjoin hashmap key value)
		(successor seed))))))

;; Predicates

(define (hashmap-empty? hashmap)
  (assume (hashmap? hashmap))
  (= (hashmap-size hashmap) 0))

(define (hashmap-contains? hashmap key)
  (assume (hashmap? hashmap))
  (hamt-contains? (hashmap-hamt hashmap) key))

(define (hashmap-disjoint? hashmap1 hashmap2)
  (assume (hashmap? hashmap1))
  (assume (hashmap? hashmap2))
  (call/cc
   (lambda (return)
     (hashmap-for-each (lambda (key value)
                         (when (hashmap-contains? hashmap2 key)
                           (return #f)))
                       hashmap1)
     #t)))

;; Accessors

(define hashmap-ref
  (case-lambda
    ((hashmap key)
     (assume (hashmap? hashmap))
     (hashmap-ref hashmap key (lambda ()
                                (error "hashmap-ref: key not in hashmap" key))))
    ((hashmap key failure)
     (assume (hashmap? hashmap))
     (assume (procedure? failure))
     (hashmap-ref hashmap key failure values))
    ((hashmap key failure success)
     (assume (hashmap? hashmap))
     (assume (procedure? failure))
     (assume (procedure? success))
     (let ((value (hamt-ref (hashmap-hamt hashmap) key singleton)))
       (if (eq? value singleton)
           (failure)
           (success value))))))

(define (hashmap-ref/default hashmap key default)
  (assume (hashmap? hashmap))
  (hashmap-ref hashmap key (lambda () default)))

;; Updaters

(define (hashmap-adjoin hashmap . args)
  (assume (hashmap? hashmap))
  (let loop ((args args)
	     (hashmap hashmap))
    (if (null? args)
	hashmap
	(receive (hashmap value) (hashmap-intern hashmap (car args) (lambda () (cadr args)))
	  (loop (cddr args) hashmap)))))

(define hashmap-adjoin! hashmap-adjoin)

(define (hashmap-set hashmap . args)
  (assume (hashmap? hashmap))
  (let loop ((args args)
	     (hashmap hashmap))
    (if (null? args)
	hashmap
	(let ((hashmap (hashmap-update hashmap (car args) (lambda (value) (cadr args)) (const #f))))
	  (loop (cddr args) hashmap)))))

(define hashmap-set! hashmap-set)

(define (hashmap-replace hashmap key value)
  (assume (hashmap? hashmap))
  (if (eq? singleton (hamt-ref (hashmap-hamt hashmap) key singleton))
      hashmap
      (make-hashmap (hashmap-key-comparator hashmap)
                    (hamt-set (hashmap-hamt hashmap) key value))))

(define hashmap-replace! hashmap-replace)

(define (hashmap-delete hashmap . keys)
  (assume (hashmap? hashmap))
  (hashmap-delete-all hashmap keys))

(define hashmap-delete! hashmap-delete)

(define (hashmap-delete-all hashmap keys)
  (assume (hashmap? hashmap))
  (assume (list? keys))
  (let loop ((keys keys)
             (hamt (hashmap-hamt hashmap)))
    (if (null? keys)
        (make-hashmap (hashmap-key-comparator hashmap) hamt)
        (loop (cdr keys) (hamt-delete hamt (car keys))))))

(define hashmap-delete-all! hashmap-delete-all)

(define (hashmap-intern hashmap key failure)
  (assume (hashmap? hashmap))
  (assume (procedure? failure))
  (let* ((hamt (hashmap-hamt hashmap))
         (value (hamt-ref hamt key singleton)))
    (if (eq? value singleton)
        (let ((value (failure)))
          (values (make-hashmap (hashmap-key-comparator hashmap)
                                (hamt-set hamt key value))
                  value))
        (values hashmap value))))

(define hashmap-intern! hashmap-intern)

(define hashmap-update
  (case-lambda
    ((hashmap key updater)
     (hashmap-update hashmap key updater (lambda ()
                                           (error "hashmap-update: key not found in hashmap" key))))
    ((hashmap key updater failure)
     (hashmap-update hashmap key updater failure values))
    ((hashmap key updater failure success)
     (assume (hashmap? hashmap))
     (assume (procedure? updater))
     (assume (procedure? failure))
     (assume (procedure? success))
     (let ((value (hamt-ref (hashmap-hamt hashmap) key singleton)))
       (if (eq? value singleton)
           (make-hashmap (hashmap-key-comparator hashmap)
                         (hamt-set (hashmap-hamt hashmap) key (updater (failure))))
           (make-hashmap (hashmap-key-comparator hashmap)
                         (hamt-set (hashmap-hamt hashmap) key (updater (success value)))))))))

(define hashmap-update! hashmap-update)

(define (hashmap-update/default hashmap key updater default)
  (hashmap-update hashmap key updater (const default)))

(define hashmap-update!/default hashmap-update/default)

(define hashmap-pop
  (case-lambda
    ((hashmap)
     (hashmap-pop hashmap (lambda ()
			    (error "hashmap-pop: hashmap has no association"))))
    ((hashmap failure)
     (assume (hashmap? hashmap))
     (assume (procedure? failure))
     ((call/cc
       (lambda (return-thunk)
	 (receive (key value)
	     (hashmap-find (lambda (key value) #t) hashmap (lambda () (return-thunk failure)))
	   (lambda ()
	     (values (hashmap-delete hashmap key) key value)))))))))

(define hashmap-pop! hashmap-pop)

(define (hashmap-search hashmap key failure success)
  (assume (hashmap? hashmap))
  (assume (procedure? failure))
  (assume (procedure? success))
  (let ((value (hamt-ref (hashmap-hamt hashmap) key singleton)))
    (if (eq? value singleton)
        (failure (lambda (value obj)
                   ;; insert
                   (values (make-hashmap (hashmap-key-comparator hashmap)
                                         (hamt-set (hashmap-hamt hashmap)
                                                   key
                                                   value))
                           obj))
                 ;; ignore
                 (lambda (obj) (values hashmap obj)))
        (success key
                 value
                 ;; update
                 (lambda (new-key new-value obj)
                   (values (make-hashmap (hashmap-key-comparator hashmap)
                                         (hamt-set (hamt-delete (hashmap-hamt hashmap) key)
                                                   new-key
                                                   new-value))
                           obj))
                 ;; remove
                 (lambda (obj)
                   (values (make-hashmap (hashmap-key-comparator hashmap)
                                         (hamt-delete (hashmap-hamt hashmap) key))
                           obj))))))

(define hashmap-search! hashmap-search)

;; The whole hashmap

(define (hashmap-size hashmap)
  (assume (hashmap? hashmap))
  (hamt-size (hashmap-hamt hashmap)))

(define (hashmap-find predicate hashmap failure)
  (assume (procedure? predicate))
  (assume (hashmap? hashmap))
  (assume (procedure? failure))
  (call/cc
   (lambda (return)
     (hashmap-for-each (lambda (key value)
                         (when (predicate key value)
                           (return key value)))
                       hashmap)
     (failure))))

(define (hashmap-count predicate hashmap)
  (assume (procedure? predicate))
  (assume (hashmap? hashmap))
  (hashmap-fold (lambda (key value count)
                  (if (predicate key value)
                      (+ 1 count)
                      count))
                0 hashmap))

(define (hashmap-any? predicate hashmap)
  (assume (procedure? predicate))
  (assume (hashmap? hashmap))
  (call/cc
   (lambda (return)
     (hashmap-for-each (lambda (key value)
                         (when (predicate key value)
                           (return #t)))
                       hashmap)
     #f)))

(define (hashmap-every? predicate hashmap)
  (assume (procedure? predicate))
  (assume (hashmap? hashmap))
  (not (hashmap-any? (lambda (key value)
                       (not (predicate key value)))
                     hashmap)))

(define (hashmap-keys hashmap)
  (assume (hashmap? hashmap))
  (hashmap-fold (lambda (key value keys)
		  (cons key keys))
		'() hashmap))

(define (hashmap-values hashmap)
  (assume (hashmap? hashmap))
  (hashmap-fold (lambda (key value values)
		  (cons value values))
		'() hashmap))

(define (hashmap-entries hashmap)
  (assume (hashmap? hashmap))
  (values (hashmap-keys hashmap)
	  (hashmap-values hashmap)))

;; Hashmap and folding

(define (hashmap-map proc comparator hashmap)
  (assume (procedure? proc))
  (assume (comparator? comparator))
  (assume (hashmap? hashmap))
  (hashmap-fold (lambda (key value hashmap)
                  (receive (key value)
                      (proc key value)
                    (hashmap-set hashmap key value)))
                (make-empty-hashmap comparator)
                hashmap))

(define (hashmap-for-each proc hashmap)
  (assume (procedure? proc))
  (assume (hashmap? hashmap))
  (hamt-fold (lambda (key value accumulator) (proc key value)) '() (hashmap-hamt hashmap)))

(define (hashmap-fold proc acc hashmap)
  (assume (procedure? proc))
  (assume (hashmap? hashmap))
  (hamt-fold proc acc (hashmap-hamt hashmap)))

(define (hashmap-map->list proc hashmap)
  (assume (procedure? proc))
  (assume (hashmap? hashmap))
  (hashmap-fold (lambda (key value lst)
		  (cons (proc key value) lst))
		'()
		hashmap))

(define (hashmap-filter predicate hashmap)
  (assume (procedure? predicate))
  (assume (hashmap? hashmap))
  (hashmap-fold (lambda (key value hashmap)
                  (if (predicate key value)
                      (hashmap-set hashmap key value)
                      hashmap))
                (make-empty-hashmap (hashmap-key-comparator hashmap))
                hashmap))

(define hashmap-filter! hashmap-filter)

(define (hashmap-remove predicate hashmap)
  (assume (procedure? predicate))
  (assume (hashmap? hashmap))
  (hashmap-filter (lambda (key value)
                    (not (predicate key value)))
                  hashmap))

(define hashmap-remove! hashmap-remove)

(define (hashmap-partition predicate hashmap)
  (assume (procedure? predicate))
  (assume (hashmap? hashmap))
  (values (hashmap-filter predicate hashmap)
	  (hashmap-remove predicate hashmap)))

(define hashmap-partition! hashmap-partition)

;; Copying and conversion

(define (hashmap-copy hashmap)
  (assume (hashmap? hashmap))
  hashmap)

(define (hashmap->alist hashmap)
  (assume (hashmap? hashmap))
  (hashmap-fold (lambda (key value alist)
		  (cons (cons key value) alist))
		'() hashmap))

(define (alist->hashmap comparator alist)
  (assume (comparator? comparator))
  (assume (list? alist))
  (hashmap-unfold null?
                  (lambda (alist)
                    (let ((key (caar alist))
                          (value (cdar alist)))
                      (values key value)))
                  cdr
                  alist
                  comparator))

(define (alist->hashmap! hashmap alist)
  (assume (hashmap? hashmap))
  (assume (list? alist))
  (fold (lambda (association hashmap)
	  (let ((key (car association))
		(value (cdr association)))
	    (hashmap-set hashmap key value)))
	hashmap
	alist))

;; Subhashmaps

(define hashmap=?
  (case-lambda
    ((comparator hashmap)
     (assume (hashmap? hashmap))
     #t)
    ((comparator hashmap1 hashmap2) (%hashmap=? comparator hashmap1 hashmap2))
    ((comparator hashmap1 hashmap2 . hashmaps)
     (and (%hashmap=? comparator hashmap1 hashmap2)
          (apply hashmap=? comparator hashmap2 hashmaps)))))
(define (%hashmap=? comparator hashmap1 hashmap2)
  (and (eq? (hashmap-key-comparator hashmap1) (hashmap-key-comparator hashmap2))
       (%hashmap<=? comparator hashmap1 hashmap2)
       (%hashmap<=? comparator hashmap2 hashmap1)))

(define hashmap<=?
  (case-lambda
    ((comparator hashmap)
     (assume (hashmap? hashmap))
     #t)
    ((comparator hashmap1 hashmap2)
     (assume (comparator? comparator))
     (assume (hashmap? hashmap1))
     (assume (hashmap? hashmap2))
     (%hashmap<=? comparator hashmap1 hashmap2))
    ((comparator hashmap1 hashmap2 . hashmaps)
     (assume (comparator? comparator))
     (assume (hashmap? hashmap1))
     (assume (hashmap? hashmap2))
     (and (%hashmap<=? comparator hashmap1 hashmap2)
          (apply hashmap<=? comparator hashmap2 hashmaps)))))

(define (%hashmap<=? comparator hashmap1 hashmap2)
  (assume (comparator? comparator))
  (assume (hashmap? hashmap1))
  (assume (hashmap? hashmap2))
  (hashmap-every? (lambda (key value)
		    (hashmap-ref hashmap2 key
				 (lambda ()
				   #f)
				 (lambda (stored-value)
				   (=? comparator value stored-value))))
		  hashmap1))

(define hashmap>?
  (case-lambda
    ((comparator hashmap)
     (assume (hashmap? hashmap))
     #t)
    ((comparator hashmap1 hashmap2)
     (assume (comparator? comparator))
     (assume (hashmap? hashmap1))
     (assume (hashmap? hashmap2))
     (%hashmap>? comparator hashmap1 hashmap2))
    ((comparator hashmap1 hashmap2 . hashmaps)
     (assume (comparator? comparator))
     (assume (hashmap? hashmap1))
     (assume (hashmap? hashmap2))
     (and (%hashmap>? comparator  hashmap1 hashmap2)
          (apply hashmap>? comparator hashmap2 hashmaps)))))

(define (%hashmap>? comparator hashmap1 hashmap2)
  (assume (comparator? comparator))
  (assume (hashmap? hashmap1))
  (assume (hashmap? hashmap2))
  (not (%hashmap<=? comparator hashmap1 hashmap2)))

(define hashmap<?
  (case-lambda
    ((comparator hashmap)
     (assume (hashmap? hashmap))
     #t)
    ((comparator hashmap1 hashmap2)
     (assume (comparator? comparator))
     (assume (hashmap? hashmap1))
     (assume (hashmap? hashmap2))
     (%hashmap<? comparator hashmap1 hashmap2))
    ((comparator hashmap1 hashmap2 . hashmaps)
     (assume (comparator? comparator))
     (assume (hashmap? hashmap1))
     (assume (hashmap? hashmap2))
     (and (%hashmap<? comparator  hashmap1 hashmap2)
          (apply hashmap<? comparator hashmap2 hashmaps)))))

(define (%hashmap<? comparator hashmap1 hashmap2)
  (assume (comparator? comparator))
  (assume (hashmap? hashmap1))
  (assume (hashmap? hashmap2))
  (%hashmap>? comparator hashmap2 hashmap1))

(define hashmap>=?
  (case-lambda
    ((comparator hashmap)
     (assume (hashmap? hashmap))
     #t)
    ((comparator hashmap1 hashmap2)
     (assume (comparator? comparator))
     (assume (hashmap? hashmap1))
     (assume (hashmap? hashmap2))
     (%hashmap>=? comparator hashmap1 hashmap2))
    ((comparator hashmap1 hashmap2 . hashmaps)
     (assume (comparator? comparator))
     (assume (hashmap? hashmap1))
     (assume (hashmap? hashmap2))
     (and (%hashmap>=? comparator hashmap1 hashmap2)
          (apply hashmap>=? comparator hashmap2 hashmaps)))))

(define (%hashmap>=? comparator hashmap1 hashmap2)
  (assume (comparator? comparator))
  (assume (hashmap? hashmap1))
  (assume (hashmap? hashmap2))
  (not (%hashmap<? comparator hashmap1 hashmap2)))

;; Set theory operations

(define (%hashmap-union hashmap1 hashmap2)
  (hashmap-fold (lambda (key2 value2 hashmap)
		  (receive (hashmap obj)
		      (hashmap-search hashmap
				      key2
				      (lambda (insert ignore)
					(insert value2 #f))
				      (lambda (key1 value1 update remove)
					(update key1 value1 #f)))
		    hashmap))
		hashmap1 hashmap2))

(define (%hashmap-intersection hashmap1 hashmap2)
  (hashmap-filter (lambda (key1 value1)
                    (hashmap-contains? hashmap2 key1))
                  hashmap1))

(define (%hashmap-difference hashmap1 hashmap2)
  (hashmap-fold (lambda (key2 value2 hashmap)
                  (receive (hashmap obj)
                      (hashmap-search hashmap
                                      key2
                                      (lambda (insert ignore)
                                        (ignore #f))
                                      (lambda (key1 value1 update remove)
                                        (remove #f)))
                    hashmap))
                hashmap1 hashmap2))

(define (%hashmap-xor hashmap1 hashmap2)
  (hashmap-fold (lambda (key2 value2 hashmap)
                  (receive (hashmap obj)
                      (hashmap-search hashmap
                                      key2
                                      (lambda (insert ignore)
                                        (insert value2 #f))
                                      (lambda (key1 value1 update remove)
                                        (remove #f)))
                    hashmap))
                hashmap1 hashmap2))

(define hashmap-union
  (case-lambda
    ((hashmap)
     (assume (hashmap? hashmap))
     hashmap)
    ((hashmap1 hashmap2)
     (assume (hashmap? hashmap1))
     (assume (hashmap? hashmap2))
     (%hashmap-union hashmap1 hashmap2))
    ((hashmap1 hashmap2 . hashmaps)
     (assume (hashmap? hashmap1))
     (assume (hashmap? hashmap2))
     (apply hashmap-union (%hashmap-union hashmap1 hashmap2) hashmaps))))
(define hashmap-union! hashmap-union)

(define hashmap-intersection
  (case-lambda
    ((hashmap)
     (assume (hashmap? hashmap))
     hashmap)
    ((hashmap1 hashmap2)
     (assume (hashmap? hashmap1))
     (assume (hashmap? hashmap2))
     (%hashmap-intersection hashmap1 hashmap2))
    ((hashmap1 hashmap2 . hashmaps)
     (assume (hashmap? hashmap1))
     (assume (hashmap? hashmap2))
     (apply hashmap-intersection (%hashmap-intersection hashmap1 hashmap2) hashmaps))))
(define hashmap-intersection! hashmap-intersection)

(define hashmap-difference
  (case-lambda
    ((hashmap)
     (assume (hashmap? hashmap))
     hashmap)
    ((hashmap1 hashmap2)
     (assume (hashmap? hashmap1))
     (assume (hashmap? hashmap2))
     (%hashmap-difference hashmap1 hashmap2))
    ((hashmap1 hashmap2 . hashmaps)
     (assume (hashmap? hashmap1))
     (assume (hashmap? hashmap2))
     (apply hashmap-difference (%hashmap-difference hashmap1 hashmap2) hashmaps))))
(define hashmap-difference! hashmap-difference)

(define hashmap-xor
  (case-lambda
    ((hashmap)
     (assume (hashmap? hashmap))
     hashmap)
    ((hashmap1 hashmap2)
     (assume (hashmap? hashmap1))
     (assume (hashmap? hashmap2))
     (%hashmap-xor hashmap1 hashmap2))
    ((hashmap1 hashmap2 . hashmaps)
     (assume (hashmap? hashmap1))
     (assume (hashmap? hashmap2))
     (apply hashmap-xor (%hashmap-xor hashmap1 hashmap2) hashmaps))))
(define hashmap-xor! hashmap-xor)

;; Comparators

(define (hashmap-equality comparator)
  (assume (comparator? comparator))
  (lambda (hashmap1 hashmap2)
    (hashmap=? comparator hashmap1 hashmap2)))

(define (hashmap-hash-function comparator)
  (assume (comparator? comparator))
  (lambda (hashmap)
    0 ;; TODO
    #;
    (default-hash (hashmap->alist hashmap))))

(define (make-hashmap-comparator comparator)
  (make-comparator hashmap?
		   (hashmap-equality comparator)
		   #f
		   (hashmap-hash-function comparator)))

(define hashmap-comparator (make-hashmap-comparator (make-default-comparator)))

(comparator-register-default! hashmap-comparator)