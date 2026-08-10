;;;; t/package.lisp
(defpackage #:cl-nyancat/test
  (:use #:cl #:cl-nyancat)
  ;; DESCRIBE clashes with CL:DESCRIBE, so shadow-import cl-weave's.
  (:shadowing-import-from #:cl-weave #:describe)
  (:import-from #:cl-weave
                #:it #:it-each #:expect #:signals #:run-all #:with-soft-assertions
                #:it-property #:gen-integer #:run-mutations #:assert-mutation-score)
  ;; Test-only cl-tty-kit primitives. cl-nyancat imports these into its own
  ;; package already (src/package.lisp) but does not re-export them as part of
  ;; its own public API -- an application does not forward its rendering
  ;; library's primitives -- so tests that drive SCREEN or the decoder directly
  ;; import them here instead. DECODE-INPUT is the one-shot decoder that builds
  ;; KEY-EVENTs from a plain string, which is the simplest way to exercise
  ;; WORLD-APPLY-KEY-EVENT without hand-composing escape sequences; the shipped
  ;; application only needs the incremental DECODE-INPUT-CHUNK (src/app.lisp).
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
  (unless (run-all :reporter :spec)
    (error "cl-nyancat test suite failed"))
  (format t "~&cl-nyancat/test: successful completion with 0 failures~%")
  t)
