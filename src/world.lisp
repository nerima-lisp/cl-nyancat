;;;; src/world.lisp -- animation state and cat placement.
(in-package #:cl-nyancat)

(defparameter +default-width+ 80)
(defparameter +default-height+ 24)
(defparameter +default-seed+ 0)

(defparameter +cat-horizontal-fraction+ 11/20
  "Where the cat's left edge sits, as a fraction of the terminal width.")

(defstruct (world (:constructor %make-world))
  "The whole animation. WIDTH and HEIGHT are the drawable area, TICK counts
ticks elapsed, SEED selects the starfield, and COLORP controls styling. Those
values determine every drawn cell because the starfield and rainbow are pure
functions of them (starfield.lisp, rainbow.lisp). COLORP is false under --no-color;
QUITP is the flag input.lisp sets on q or Ctrl-C; MAX-TICKS is the tick at
which --duration expires, or NIL to run until interrupted. CAT-X and CAT-Y are
the cat sprite's top-left cell, recomputed by %PLACE-CAT on every resize."
  (width 0 :type fixnum)
  (height 0 :type fixnum)
  (tick 0 :type fixnum)
  (seed 0 :type integer)
  (colorp t :type boolean)
  (quitp nil :type boolean)
  (max-ticks nil :type (or null fixnum))
  (cat-x 0 :type fixnum)
  (cat-y 0 :type fixnum))

(defun %assert-dimensions (width height)
  "Signal NYANCAT-INVALID-DIMENSIONS unless WIDTH and HEIGHT are both positive
integers."
  (unless (and (integerp width) (plusp width) (integerp height) (plusp height))
    (error 'nyancat-invalid-dimensions :width width :height height))
  (values))

(defun %place-cat (world)
  "Recompute WORLD's CAT-X and CAT-Y from its current size, returning WORLD.
The sprite is kept fully on screen when it fits and pinned to the top-left
corner when it does not, so a terminal narrower or shorter than the cat still
renders something rather than clipping to nothing."
  (let ((slack-x (max 0 (- (world-width world) (cat-art-width))))
        (slack-y (max 0 (- (world-height world) (cat-art-height)))))
    (setf (world-cat-x world)
          (clamp (round (* (world-width world) +cat-horizontal-fraction+)) 0 slack-x)
          (world-cat-y world)
          (clamp (floor slack-y 2) 0 slack-y)))
  world)

(defun make-world (&key (width +default-width+) (height +default-height+)
                     (seed +default-seed+) (colorp t) max-ticks)
  "Create a WORLD of WIDTH by HEIGHT rendering the starfield selected by SEED.
COLORP false renders in plain ASCII with no escape sequences beyond cursor
movement. MAX-TICKS, when supplied, is the tick count at which WORLD-FINISHED-P
becomes true; NIL runs until the user interrupts. A non-positive WIDTH or
HEIGHT signals NYANCAT-INVALID-DIMENSIONS."
  (%assert-dimensions width height)
  (%place-cat (%make-world :width width :height height
                           :seed seed :colorp (and colorp t)
                           :max-ticks max-ticks)))

(defun world-resize (world width height)
  "Resize WORLD to WIDTH by HEIGHT in place and re-place the cat, returning WORLD.
The tick is not reset: the starfield and rainbow are functions of the tick and
the screen column, so they simply reveal more or less of themselves at the new
size rather than needing to be rebuilt. A non-positive WIDTH or HEIGHT signals
NYANCAT-INVALID-DIMENSIONS."
  (%assert-dimensions width height)
  (setf (world-width world) width
        (world-height world) height)
  (%place-cat world))
