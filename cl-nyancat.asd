;;;; cl-nyancat.asd

;;; This form comes FIRST, before any defsystem. ASDF binds *package* to
;;; ASDF-USER only for a file it loads itself; read any other way -- a REPL
;;; `load`, an editor evaluating the buffer, flake.nix parsing :version --
;;; the file is read in whatever package happens to be current, and an
;;; unqualified `defsystem` then fails to read at all. See
;;; PACKAGE_STANDARD.md "asd の書き方".
;;;
;;; No sibling package's prefix (cl-tty-kit:, cl-cli:, cl-nyancat/test:) may
;;; appear anywhere below. :DEPENDS-ON is not processed until the whole file
;;; has been READ, so a qualified symbol naming a package that does not exist
;;; yet is a hard read-time error, not a load-time one. The :PERFORM clause at
;;; the bottom therefore reaches its test runner through FIND-PACKAGE /
;;; FIND-SYMBOL / FUNCALL, all of which are CL symbols.
(in-package #:asdf-user)

(defsystem "cl-nyancat"
  :description "An original pop-tart cat rainbow animation for the terminal."
  :long-description "A grey cat riding an original ASCII-art pop-tart body trails a
six-band rainbow across a scrolling starfield, animated live in the terminal via
cl-tty-kit. Every sprite is original art authored for this repository, not a port of
any existing nyancat implementation. The starfield is a pure function of (seed, column,
row, tick) rather than a random-state walk, so a given --seed renders byte-identically
on every run. SBCL only."
  :author "takeokunn <bararararatty@gmail.com>"
  :maintainer "takeokunn <bararararatty@gmail.com>"
  :license "MIT"
  ;; Single source of truth for the version. flake.nix reads this form, and
  ;; release.yml refuses to publish a tag that disagrees with it.
  :version "0.1.0"
  :homepage "https://github.com/nerima-lisp/cl-nyancat"
  :bug-tracker "https://github.com/nerima-lisp/cl-nyancat/issues"
  :source-control (:git "https://github.com/nerima-lisp/cl-nyancat.git")
  :depends-on ("cl-tty-kit" ; screens, sprite blitting, styles, tick loop, raw mode, input
               "cl-cli")    ; --fps/--duration/--seed/--no-color parsing, --help/--version
  :pathname "src"
  :serial t
  ;; src/ is flat and every defpackage lives in src/package.lisp.
  :components ((:file "package")
               (:file "conditions")
               (:file "geometry")
               (:file "palette")
               (:file "art-cat")
               (:file "starfield")
               (:file "rainbow")
               (:file "world")
               (:file "update")
               (:file "input")
               (:file "render")
               (:file "app")
               (:file "cli"))
  ;; Delivers the `cl-nyancat` executable via `(asdf:operate 'asdf:program-op
  ;; "cl-nyancat")` / `nix build`, both driven from these three keys -- see
  ;; cl-asciiquarium.asd, which this follows, and flake.nix's `executable` block.
  :build-operation "program-op"
  :build-pathname "cl-nyancat"
  :entry-point "cl-nyancat::image-entry-point"
  ;; Mandatory. Without it `asdf:test-system "cl-nyancat"` succeeds while
  ;; running zero tests. See PACKAGE_STANDARD.md.
  :in-order-to ((test-op (test-op "cl-nyancat/test"))))

;;; The test system is `cl-nyancat/test` (singular, slash-separated) with
;;; :pathname "t". It is NOT `cl-nyancat-test` and NOT `cl-nyancat/tests`.
(defsystem "cl-nyancat/test"
  :description "Test system for cl-nyancat."
  :author "takeokunn <bararararatty@gmail.com>"
  :maintainer "takeokunn <bararararatty@gmail.com>"
  :license "MIT"
  :version "0.1.0"
  :homepage "https://github.com/nerima-lisp/cl-nyancat"
  :bug-tracker "https://github.com/nerima-lisp/cl-nyancat/issues"
  :source-control (:git "https://github.com/nerima-lisp/cl-nyancat.git")
  ;; cl-weave is the org's test framework everywhere. Do not introduce FiveAM,
  ;; parachute, rove or prove.
  ;;
  ;; Test-only: cl-tty-kit for DECODE-INPUT (t/input-test.lisp builds KEY-EVENTs
  ;; from a plain string) and for MAKE-SCREEN/SCREEN-CELL (t/render-test.lisp
  ;; asserts on painted cells). It is already the main system's own dependency,
  ;; at the same layer, so this stays within DEPENDENCY_POLICY.md's test-only
  ;; dependency limit.
  :depends-on ("cl-nyancat" "cl-weave" "cl-tty-kit")
  :pathname "t"
  :serial t
  :components ((:file "package")
               (:file "geometry-test")
               (:file "palette-test")
               (:file "art-cat-test")
               (:file "starfield-test")
               (:file "rainbow-test")
               (:file "world-test")
               (:file "update-test")
               (:file "input-test")
               (:file "render-test")
               (:file "cli-test"))
  ;; ADR-0081: no uiop:symbol-call here. FIND-PACKAGE / FIND-SYMBOL / FUNCALL
  ;; are all CL symbols, so this clause reads without depending on anything
  ;; :DEPENDS-ON has not loaded yet.
  :perform (test-op (op system)
             (declare (ignore op system))
             (unless (funcall (find-symbol "RUN-TESTS" (find-package "CL-NYANCAT/TEST")))
               (error "cl-nyancat test suite failed"))))
