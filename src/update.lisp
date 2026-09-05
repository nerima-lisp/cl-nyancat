;;;; src/update.lisp -- deterministic world state transitions.
;;;;
;;;; WORLD-ADVANCE updates the tick; rendering and terminal I/O live elsewhere.
(in-package #:cl-nyancat)

(defun world-advance (world)
  "Advance WORLD by one tick in place and return WORLD."
  (incf (world-tick world))
  world)

(defun world-finished-p (world)
  "Return true when WORLD is quitting or has reached its MAX-TICKS limit."
  (or (world-quitp world)
      (and (world-max-ticks world)
           (>= (world-tick world) (world-max-ticks world)))))

(defun world-cat-frame (world)
  "Return the cat sprite text to draw for WORLD's current tick."
  (cat-frame (cat-frame-for-tick (world-tick world))))
