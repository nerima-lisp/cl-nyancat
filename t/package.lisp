;;;; t/package.lisp
(defpackage #:cl-nyancat/test
  (:use #:cl #:cl-nyancat)
  ;; DESCRIBE clashes with CL:DESCRIBE, so shadow-import cl-weave's.
  (:shadowing-import-from #:cl-weave #:describe)
  (:import-from #:cl-weave
                #:it #:it-each #:expect #:signals #:run-all #:with-soft-assertions
                #:it-property #:gen-integer)
  ;; Tests import these non-public cl-tty-kit primitives to drive screens and
  ;; decode string input without constructing key events by hand.
  (:import-from #:cl-tty-kit
                #:decode-input
                #:make-screen
                #:make-renderer
                #:screen-cell
                #:screen-to-string
                #:cell-char
                #:cell-style)
  ;; Test-only cl-cli primitives for t/cli-test.lisp: PARSE-ARGV drives *APP*
  ;; through cl-cli's own parser without dispatching the handler, which would
  ;; take over the terminal.
  (:import-from #:cl-cli
                #:parse-argv
                #:run-app
                #:option-value
                #:cli-invalid-option-value)
  (:export #:run-tests))

(in-package #:cl-nyancat/test)

(defun run-tests ()
  "Run every registered spec, signalling on any failure so ASDF's TEST-OP fails.
Nothing in this suite binds CL:*RANDOM-STATE*, unlike cl-asciiquarium's: this
package has no random state to pin. The starfield is a pure hash of (seed,
column, row) (src/starfield.lisp), so a determinism test here is an equality
assertion between two calls rather than a seeded replay."
  (unless (run-all :reporter :spec :pass-with-no-tests nil)
    (error "cl-nyancat test suite failed"))
  (format t "~&cl-nyancat/test: successful completion with 0 failures~%")
  t)
