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

(defun %nyancat-crop-option-name (token)
  (labels ((long-option-p (name)
             (or (string= token name)
                 (and (> (length token) (length name))
                      (string= token name :end1 (length name))
                      (char= (char token (length name)) #\=)))))
    (cond
      ((long-option-p "--min-rows") :min-rows)
      ((long-option-p "--max-rows") :max-rows)
      ((long-option-p "--min-cols") :min-cols)
      ((long-option-p "--max-cols") :max-cols)
      ((long-option-p "--width") :width)
      ((long-option-p "--height") :height)
      ((and (>= (length token) 2)
            (char= (char token 0) #\-))
       (let ((option-character (char token 1)))
         (cond
           ((char= option-character #\r) :min-rows)
           ((char= option-character #\R) :max-rows)
           ((char= option-character #\c) :min-cols)
           ((char= option-character #\C) :max-cols)
           ((char= option-character #\W) :width)
           ((char= option-character #\H) :height)
           (t nil))))
      (t nil))))

(defun %nyancat-crop-options (invocation)
  "Apply crop options in raw argv order, like upstream getopt."
  (let ((min-row nil)
        (max-row nil)
        (min-col nil)
        (max-col nil)
        (saw-crop-option-p nil))
    (dolist (token (invocation-raw-argv invocation))
      (when (string= token "--")
        (return))
      (let ((option (%nyancat-crop-option-name token)))
        (when option
          (setf saw-crop-option-p t)
          (case option
            (:min-rows (setf min-row (option-value invocation :min-rows)))
            (:max-rows (setf max-row (option-value invocation :max-rows)))
            (:min-cols (setf min-col (option-value invocation :min-cols)))
            (:max-cols (setf max-col (option-value invocation :max-cols)))
            (:width
             (multiple-value-bind (minimum maximum)
                 (%crop-bounds 64 nil nil (option-value invocation :width))
               (setf min-col minimum
                     max-col maximum)))
            (:height
             (multiple-value-bind (minimum maximum)
                 (%crop-bounds 64 nil nil (option-value invocation :height))
               (setf min-row minimum
                     max-row maximum)))))))
    (if saw-crop-option-p
        (values min-row max-row min-col max-col nil nil)
        (values (option-value invocation :min-rows)
                (option-value invocation :max-rows)
                (option-value invocation :min-cols)
                (option-value invocation :max-cols)
                (option-value invocation :width)
                (option-value invocation :height)))))

(defun %run-handler (invocation)
  "The cl-cli:RUN-APP handler starts the animation from parsed INVOCATION flags. Returns 0 once RUN returns, which is when the user quit or --duration expired."
  (multiple-value-bind (min-rows max-rows min-cols max-cols crop-width crop-height)
      (%nyancat-crop-options invocation)
    (run :seed (or (option-value invocation :seed) +default-seed+)
         :colorp (not (option-value invocation :no-color))
         :fps (or (option-value invocation :fps) +default-fps+)
         :duration (option-value invocation :duration)
         :frames (option-value invocation :frames)
         :intro-p (option-value invocation :intro)
         :skip-intro-p (option-value invocation :skip-intro)
         :telnet-p (option-value invocation :telnet)
         :show-counter-p (not (option-value invocation :no-counter))
         :set-title-p (not (option-value invocation :no-title))
         :clear-screen-p (not (option-value invocation :no-clear))
         :min-rows min-rows
         :max-rows max-rows
         :min-cols min-cols
         :max-cols max-cols
         :crop-width crop-width
         :crop-height crop-height))
  0)

(defparameter *app*
  (make-app
   :name "cl-nyancat"
   :version (%nyancat-version)
   :summary "A terminal Nyancat animation."
   :description "A terminal animation using the upstream Nyancat frame sequence.
Press q or Ctrl-C to quit, c to toggle color."
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
                      "Render in plain ASCII, with one glyph per animation color and no color.")
         (make-option :name "intro" :short #\i :kind :flag
                      :description "Show the introduction at startup.")
         (make-option :name "skip-intro" :short #\I :kind :flag
                      :description "Skip the introduction.")
         (make-option :name "telnet" :short #\t :kind :flag
                      :description "Use the telnet introduction mode.")
         (make-option :name "no-counter" :short #\n :kind :flag
                      :description "Do not display the timer.")
         (make-option :name "no-title" :short #\s :kind :flag
                      :description "Do not set the terminal title.")
         (make-option :name "no-clear" :short #\e :kind :flag
                      :description "Do not clear the display between frames.")
         (make-option :name "frames" :short #\f :kind :value :type :integer :min 0
                      :description "Display this many frames, then quit.")
         (make-option :name "min-rows" :short #\r :kind :value :type :integer
                      :description "Crop the animation from the top.")
         (make-option :name "max-rows" :short #\R :kind :value :type :integer
                      :description "Crop the animation from the bottom.")
         (make-option :name "min-cols" :short #\c :kind :value :type :integer
                      :description "Crop the animation from the left.")
         (make-option :name "max-cols" :short #\C :kind :value :type :integer
                      :description "Crop the animation from the right.")
         (make-option :name "width" :short #\W :kind :value :type :integer :min 1
                      :description "Crop the animation to this width.")
         (make-option :name "height" :short #\H :kind :value :type :integer :min 1
                      :description "Crop the animation to this height."))
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
