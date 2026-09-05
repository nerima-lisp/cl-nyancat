;;;; src/update.lisp -- the one pure state transition, old world in, new world out.
;;;;
;;;; This is the deterministic half of the split cl-tty-kit's tick-loop.lisp
;;;; file header describes: nothing below reads a clock, a terminal, or
;;;; *RANDOM-STATE*, so t/update-test.lisp can drive ten thousand ticks in a
;;;; plain image and assert on the exact result. Real I/O is confined to
;;;; app.lisp.
(in-package #:cl-nyancat)

(defun world-advance (world)
  "Advance WORLD by one tick in place, returning WORLD.
The tick is the whole transition: the starfield scrolls, the rainbow's wave
travels and the cat's paws swap purely as functions of it, so there is no
per-object state to step. WORLD is mutated rather than copied, matching the
in-place contract cl-tty-kit's TICK-LOOP-RUN threads its state through."
  (incf (world-tick world))
  world)

(defun world-finished-p (world)
  "True when the animation should stop: the user quit, or --duration expired.
This is the STOP predicate app.lisp hands to TICK-LOOP-RUN-REALTIME. A WORLD
with no MAX-TICKS is finished only once WORLD-QUITP is set."
  (or (world-quitp world)
      (and (world-max-ticks world)
           (>= (world-tick world) (world-max-ticks world)))))

(defun world-cat-frame (world)
  "Return the cat sprite text to draw for WORLD's current tick."
  (cat-frame (cat-frame-for-tick (world-tick world))))
