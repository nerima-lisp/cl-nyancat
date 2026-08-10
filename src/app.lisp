;;;; src/app.lisp -- the thin real-IO loop.
;;;;
;;;; Everything below does real terminal I/O; nothing in update.lisp,
;;;; starfield.lisp or rainbow.lisp does. That is the split cl-tty-kit's
;;;; examples/renderer-loop.lisp establishes and the reason this file is the
;;;; only one in src/ without a test in t/: there is nothing left in it to
;;;; test that a real terminal would not have to supply.
(in-package #:cl-nyancat)

(defparameter +default-fps+ 12
  "Frames per second when --fps is not given. Nyancat's own animation cycle is
slow and deliberate; 12 is enough to make the paws trot and the rainbow ripple
without the starfield turning into static.")

(defun %read-available-string (stream)
  "Return every character currently buffered on STREAM, without blocking, as a string.
Used instead of cl-tty-kit's fd-level octet reader because *STANDARD-INPUT*
here is a plain character stream on the controlling terminal, not a bare fd
this application owns the non-blocking mode of; READ-CHAR-NO-HANG already
returns NIL rather than blocking when nothing is buffered."
  (with-output-to-string (out)
    (loop for char = (read-char-no-hang stream nil nil)
          while char
          do (write-char char out))))

(defun %poll-input-events (decoder stream)
  "Feed any input currently available on STREAM through DECODER.
Returns the decoded cl-tty-kit KEY-EVENTs, or NIL when nothing was available."
  (let ((chunk (%read-available-string stream)))
    (when (plusp (length chunk))
      (decode-input-chunk decoder chunk))))

(defun %poll-resize (world renderer)
  "Resize WORLD and RENDERER to the terminal's current size when it has changed.
Returns WORLD. cl-tty-kit polls rather than trapping SIGWINCH (see its
terminal-size.lisp file header), so this application does the same, once per
tick from %ADVANCE-WITH-IO."
  (multiple-value-bind (columns rows) (terminal-size)
    (when (and columns rows
               (or (/= columns (world-width world)) (/= rows (world-height world))))
      (world-resize world columns rows)
      (renderer-resize renderer columns rows)))
  world)

(defun %advance-with-io (world renderer decoder)
  "The realtime loop's ADVANCE function: poll for a resize and for key input,
apply any decoded key events, then run the one pure simulation step."
  (%poll-resize world renderer)
  (world-apply-key-events world (%poll-input-events decoder *standard-input*))
  (world-advance world))

(defun %duration-to-ticks (duration fps)
  "Return the tick count DURATION seconds corresponds to at FPS, or NIL for a NIL DURATION.
Rounded up and floored at one tick, so `--duration 0.01` still draws a frame
instead of exiting before anything reaches the terminal."
  (and duration (max 1 (ceiling (* duration fps)))))

(defun %crop-bounds (frame-size min-value max-value requested-size)
  "Resolve a centered REQUESTED-SIZE or preserve explicit MIN-VALUE/MAX-VALUE."
  (if requested-size
      (values (truncate (- frame-size requested-size) 2)
              (truncate (+ frame-size requested-size) 2))
      (values min-value max-value)))

(defparameter +nyancat-title+ "Nyanyanyanyanyanyanya...")

(defun %write-nyancat-title (stream)
  (format stream "~Ck~A~C\\~C]1;~A~C~C]2;~A~C"
          (code-char 27) +nyancat-title+ (code-char 27)
          (code-char 27) +nyancat-title+ (code-char 7)
          (code-char 27) +nyancat-title+ (code-char 7)))

(defun %write-nyancat-raw-string (stream string)
  (loop for character across string
        do (when (char= character #\Newline)
             (write-char #\Return stream))
           (write-char character stream)))

(defun %write-nyancat-intro (stream clear-screen-p)
  (dotimes (index 5)
    (%write-nyancat-raw-string
     stream
     (format nil
              "~3%                             ~C[1mNyancat Telnet Server~C[0m~2%                   written and run by ~C[1;32mK. Lange~C[1;34m @_klange~C[0m~2%        If things don't look right, try:~%                TERM=fallback telnet ...~2%        Or on Windows:~%                telnet -t vtnt ...~2%        Problems? Check the website:~%                ~C[1;34mhttp://nyancat.dakko.us~C[0m~2%        This is a telnet server, remember your escape keys!~%                ~C[1;31m^]quit~C[0m to exit~2%        Starting in ~D...                ~%"
             (code-char 27) (code-char 27) (code-char 27)
             (code-char 27) (code-char 27) (code-char 27)
             (code-char 27) (code-char 27) (code-char 27)
             (- 5 index)))
    (force-output stream)
    (sleep 0.4)
    (if clear-screen-p
        (format stream "~C[H" (code-char 27))
        (format stream "~C[u" (code-char 27))))
  (when clear-screen-p
    (format stream "~C[H~C[2J~C[?25l"
            (code-char 27) (code-char 27) (code-char 27))))

(defun %write-nyancat-start (stream clear-screen-p)
  (if clear-screen-p
      (format stream "~C[H~C[2J~C[?25l"
              (code-char 27) (code-char 27) (code-char 27))
      (format stream "~C[s" (code-char 27))))

(defun %nyancat-frame-prefix (clear-screen-p)
  (if clear-screen-p
      (format nil "~C[H" (code-char 27))
      (format nil "~C[u" (code-char 27))))

(defun %write-nyancat-finish (stream clear-screen-p)
  (if clear-screen-p
      (format stream "~C[?25h~C[0m~C[H~C[2J"
              (code-char 27) (code-char 27) (code-char 27) (code-char 27))
      (format stream "~C[0m~C~%" (code-char 27) #\Return)))

(defun run (&key width height (seed +default-seed+) (colorp t) (fps +default-fps+)
              duration frames intro-p skip-intro-p telnet-p
              (show-counter-p t) (set-title-p t) (clear-screen-p t)
              min-rows max-rows min-cols max-cols crop-width crop-height
              (stream *standard-output*))
  "Animate the cat in the real terminal, returning the final WORLD.
WIDTH and HEIGHT default to the detected terminal size and are then kept up to
date automatically (see %POLL-RESIZE). SEED selects the legacy starfield;
COLORP false renders the fallback glyphs; FPS is the target frame rate.
DURATION and FRAMES stop the animation after their respective limits, and
without either the loop runs until q, Q or Ctrl-C. The crop arguments select
the source rectangle in the upstream 64x64 animation. INTRO-P and TELNET-P
request the upstream introduction; SKIP-INTRO-P suppresses it. The terminal
is kept on the current screen, matching the standalone nyancat command."
  (multiple-value-bind (detected-columns detected-rows) (terminal-size)
    (multiple-value-bind (min-col max-col)
        (%crop-bounds 64 min-cols max-cols crop-width)
      (multiple-value-bind (min-row max-row)
          (%crop-bounds 64 min-rows max-rows crop-height)
        (let* ((width (or width detected-columns +default-width+))
               (height (or height detected-rows +default-height+))
               (max-ticks (or (and frames (unless (zerop frames) frames))
                              (%duration-to-ticks duration fps)))
           (world (make-world :width width :height height :seed seed :colorp colorp
                              :max-ticks max-ticks :frame-rate fps
                              :show-counter-p show-counter-p
                              :set-title-p set-title-p
                              :clear-screen-p clear-screen-p
                              :min-row min-row :max-row max-row
                              :min-col min-col :max-col max-col))
           (renderer (make-renderer width height))
           (decoder (make-input-decoder)))
          (with-raw-mode ()
            (with-terminal-session (session-stream :stream stream
                                                   :hide-cursor nil
                                                   :alternate-screen nil)
              (when (and set-title-p (not telnet-p))
                (%write-nyancat-title session-stream))
              (%write-nyancat-start session-stream clear-screen-p)
              (when (and (or intro-p telnet-p) (not skip-intro-p))
                (%write-nyancat-intro session-stream clear-screen-p))
              (force-output session-stream)
              (unwind-protect
                   (tick-loop-run-realtime
                    world
                    (lambda (state) (%advance-with-io state renderer decoder))
                    (lambda (state)
                      (concatenate 'string
                                   (%nyancat-frame-prefix clear-screen-p)
                                   (%render-nyancat-terminal-frame-for-cli state)))
                    #'world-finished-p
                    :stream session-stream
                    :interval (/ 1 fps))
                (%write-nyancat-finish session-stream clear-screen-p)
                (force-output session-stream)))))))))
