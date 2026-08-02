;;;; src/cli.lisp -- the command-line surface (cl-cli) and the executable's
;;;; entry points. Follows the small-app delivery pattern the sibling toys use:
;;;; *APP* is the declarative spec, MAIN drives it under a normal Lisp image,
;;;; and IMAGE-ENTRY-POINT (named by :ENTRY-POINT in cl-nyancat.asd) is the
;;;; toplevel of the `cl-nyancat` binary that `nix build` and
;;;; `(asdf:operate 'asdf:program-op ...)` both produce.
(in-package #:cl-nyancat)

(defun %nyancat-version ()
  "Return the running CL-NYANCAT system's :VERSION as a string.
Read from ASDF rather than copied into a literal here, so --version cannot
drift from the version bump in cl-nyancat.asd -- the same value flake.nix reads
and release.yml enforces against the git tag. Falls back to \"0.0.0\" when the
system is not registered, which is the case inside a delivered image built
without installed sources."
  (let ((system (asdf:find-system "cl-nyancat" nil)))
    (if system (asdf:component-version system) "0.0.0")))

(defun %run-handler (invocation)
  "The handler cl-cli:RUN-APP dispatches to: start the animation from INVOCATION's
parsed flags. Returns 0 once RUN returns, which is when the user quit or
--duration expired."
  (run :seed (or (option-value invocation :seed) +default-seed+)
       :colorp (not (option-value invocation :no-color))
       :fps (or (option-value invocation :fps) +default-fps+)
       :duration (option-value invocation :duration))
  0)

(defparameter *app*
  (make-app
   :name "cl-nyancat"
   :version (%nyancat-version)
   :summary "An original pop-tart cat rainbow animation for the terminal."
   :description "A grey cat riding a sprinkled pop-tart trails a six-band
rainbow across a scrolling starfield. Press q or Ctrl-C to quit, c to toggle
color."
   :global-options
   (list (make-option :name "fps" :kind :value :type :integer :min 1 :max 60
                      :description "Target frames per second (default 12).")
         (make-option :name "duration" :kind :value :type :number :min 0
                      :description
                      "Stop after this many seconds; runs until interrupted if omitted.")
         (make-option :name "seed" :kind :value :type :integer
                      :description
                      "Starfield seed; the same seed always renders the same stars.")
         (make-option :name "no-color" :kind :flag
                      :description
                      "Render in plain ASCII, with one glyph per rainbow band and no color."))
   :handler #'%run-handler)
  "The declarative cl-cli specification for the `cl-nyancat` command.")

(defun main ()
  "Entry point for a plain `sbcl --script'/REPL invocation.
Parses the current process argv against *APP* and exits with its result code."
  (uiop:quit (run-app *app* :argv (current-process-argv))))

(defun image-entry-point ()
  "Toplevel of the delivered `cl-nyancat' executable; named by :ENTRY-POINT in
cl-nyancat.asd. Identical to MAIN -- this application loads no further ASDF
systems at run time, so it needs no image-relocation bootstrapping beyond this
thin wrapper."
  (uiop:quit (run-app *app* :argv (current-process-argv))))
