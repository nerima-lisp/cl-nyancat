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

(defun run (&key width height (seed +default-seed+) (colorp t) (fps +default-fps+)
              duration (stream *standard-output*))
  "Animate the cat in the real terminal, returning the final WORLD.
WIDTH and HEIGHT default to the detected terminal size and are then kept up to
date automatically (see %POLL-RESIZE). SEED selects the starfield; COLORP false
renders plain ASCII; FPS is the target frame rate; DURATION, in seconds, stops
the animation after that long, and without it the loop runs until q, Q or
Ctrl-C. The terminal is put in raw mode on the alternate screen with the cursor
hidden, and restored on the way out."
  (multiple-value-bind (detected-columns detected-rows) (terminal-size)
    (let* ((width (or width detected-columns +default-width+))
           (height (or height detected-rows +default-height+))
           (world (make-world :width width :height height :seed seed :colorp colorp
                              :max-ticks (%duration-to-ticks duration fps)))
           (renderer (make-renderer width height))
           (decoder (make-input-decoder)))
      (with-raw-mode ()
        (with-terminal-session (session-stream :stream stream
                                               :hide-cursor t :alternate-screen t)
          (tick-loop-run-realtime
           world
           (lambda (state) (%advance-with-io state renderer decoder))
           (lambda (state) (render-frame renderer state))
           #'world-finished-p
           :stream session-stream
           :interval (/ 1 fps)))))))
