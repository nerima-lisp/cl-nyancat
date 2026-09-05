;;;; src/cli.lisp -- the command-line surface and executable entry points.
;;;; *APP* is the declarative spec, MAIN drives it under a normal Lisp image,
;;;; and IMAGE-ENTRY-POINT is the toplevel of the delivered binary.
(in-package #:cl-nyancat)

(defun %nyancat-version ()
  "Return the registered CL-NYANCAT system version, or \"0.0.0\" when the
system is not registered."
  (let ((system (asdf:find-system "cl-nyancat" nil)))
    (if system (asdf:component-version system) "0.0.0")))

(defun %run-handler (invocation)
  "Dispatch the parsed INVOCATION flags to RUN and return a zero exit status."
  (run :seed (or (option-value invocation :seed) +default-seed+)
       :colorp (not (option-value invocation :no-color))
       :fps (or (option-value invocation :fps) +default-fps+)
       :duration (option-value invocation :duration)
       :frames (option-value invocation :frames)
       :counterp (not (option-value invocation :no-counter))
       :titlep (not (option-value invocation :no-title))
       :clearp (not (option-value invocation :no-clear))
       :introp (option-value invocation :intro)
       :min-rows (or (option-value invocation :min-rows) 0)
       :max-rows (option-value invocation :max-rows)
       :min-cols (or (option-value invocation :min-cols) 0)
       :max-cols (option-value invocation :max-cols)
       :viewport-width (option-value invocation :width)
       :viewport-height (option-value invocation :height))
  0)

(defparameter *app* (make-app :name "cl-nyancat" :version (%nyancat-version) :summary "A pop-tart cat rainbow animation for the terminal." :description "A grey cat riding a sprinkled pop-tart trails a six-band rainbow across a scrolling starfield. Press q or Ctrl-C to quit, c to toggle color." :global-options (list (make-option :name "fps" :kind :value :type :integer :min 1 :max 60 :description "Target frames per second (default 12).") (make-option :name "duration" :kind :value :type :number :min 0 :description "Stop after this many seconds; runs until interrupted if omitted.") (make-option :name "frames" :short "f" :kind :value :type :integer :min 1 :description "Stop after this many frames.") (make-option :name "width" :short "W" :kind :value :type :integer :min 1 :description "Crop the animation to this width, centered by default.") (make-option :name "height" :short "H" :kind :value :type :integer :min 1 :description "Crop the animation to this height, centered by default.") (make-option :name "seed" :kind :value :type :integer :description "Starfield seed; the same seed always renders the same stars.") (make-option :name "intro" :short "i" :kind :flag :description "Show a short introduction before animation.") (make-option :name "min-rows" :short "r" :kind :value :type :integer :min 0 :description "Crop rows from the top; the maximum is exclusive.") (make-option :name "max-rows" :short "R" :kind :value :type :integer :min 0 :description "Crop rows below this exclusive row bound.") (make-option :name "min-cols" :short "c" :kind :value :type :integer :min 0 :description "Crop columns from the left; the maximum is exclusive.") (make-option :name "max-cols" :short "C" :kind :value :type :integer :min 0 :description "Crop columns before this exclusive column bound.") (make-option :name "no-color" :kind :flag :description "Render in plain ASCII, with one glyph per rainbow band and no color.") (make-option :name "no-counter" :short "n" :kind :flag :description "Do not display the elapsed-frame counter.") (make-option :name "no-title" :short "s" :kind :flag :description "Do not set the terminal title.") (make-option :name "no-clear" :short "e" :kind :flag :description "Do not clear the display between frames.")) :handler (function %run-handler)) "The declarative cl-cli specification for the cl-nyancat command.")

(defun main ()
  "Entry point for a plain `sbcl --script'/REPL invocation.
Parses the current process argv against *APP* and exits with its result code."
  (image-entry-point))

(defun image-entry-point ()
  "Toplevel of the delivered `cl-nyancat' executable; named by :ENTRY-POINT in
cl-nyancat.asd."
  (uiop:quit (run-app *app* :argv (current-process-argv))))
