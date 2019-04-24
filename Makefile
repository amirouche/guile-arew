help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

DOCUMENTATION_FILES =		\
	README.md		\
	scheme/base.md		\
	scheme/case-lambda.md	\
	scheme/char.md		\
	scheme/complex.md	\
	scheme/cxr.md		\
	scheme/eval.md		\
	scheme/file.md		\
	scheme/inexact.md	\
	scheme/lazy.md		\


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
