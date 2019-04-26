help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

DOCUMENTATION_FILES =			\
	README.md			\
	scheme/base.md			\
	scheme/bitwise.md		\
	scheme/box.md			\
	scheme/bytevector.md		\
	scheme/case-lambda.md		\
	scheme/char.md			\
	scheme/charset.md		\
	scheme/comparator.md		\
	scheme/complex.md		\
	scheme/cxr.md			\
	scheme/division.md		\
	scheme/ephemeron.md		\
	scheme/eval.md			\
	scheme/file.md			\
	scheme/fixnum.md		\
	scheme/flonum.md		\
	scheme/generator.md		\
	scheme/hash-table.md		\
	scheme/ideque.md		\
	scheme/ilist.md			\
	scheme/inexact.md		\
	scheme/lazy.md			\
	scheme/list-queue.md		\
	scheme/list.md			\
	scheme/load.md			\
	scheme/lseq.md			\
	scheme/mapping.md		\
	scheme/mapping/hash.md		\
	scheme/process-context.md	\
	scheme/r5rs.md			\
	scheme/read.md			\
	scheme/regex.md			\
	scheme/repl.md			\
	scheme/rlist.md			\
	scheme/set.md			\
	scheme/show.md			\
	scheme/sort.md			\
	scheme/stream.md		\
	scheme/text.md			\
	scheme/time.md			\
	scheme/vector.md		\
	scheme/vector/fu.md		\
	scheme/write.md

doc: ## Build the documentation with pandoc in html and pdf format.
	pandoc  $(DOCUMENTATION_FILES) -o guile-r7rs.pdf
	pandoc  $(DOCUMENTATION_FILES) -o guile-r7rs.html

smoke:
	guile -L $(PWD) smoke-test.scm

check: smoke ## Run tests
	find scheme/ -name "*-tests.scm" -print0 | xargs -0L1 guile -L $(PWD)

todo: ## Things that should be done.
	@grep -nR --color=always --before-context=2 --after-context=2 TODO src/

xxx: ## Things that require attention.
	@grep -nR --color=always --before-context=2 --after-context=2 XXX src/

repl: ## Start a guile REPL
	guile -L $(PWD)
