;;;; src/rainbow.lisp -- where the rainbow trail's bands sit, as a pure function.
;;;;
;;;; Like starfield.lisp this file computes geometry only; nothing here touches
;;;; a screen. RAINBOW-BAND-AT answers "which band, if any, covers this cell?"
;;;; for one cell at a time, so render.lisp is a double loop over the trail's
;;;; area and a test is a single call.
;;;;
;;;; The trail is a stack of +RAINBOW-BAND-COUNT+ rows whose top edge steps up
;;;; and down by one row every +RAINBOW-WAVE-PERIOD+ columns. That square wave
;;;; scrolls with the tick, so the ribbon appears to ripple away behind the cat
;;;; rather than sit still while the stars move.
(in-package #:cl-nyancat)

(defparameter +rainbow-wave-period+ 4
  "How many columns the rainbow holds each step of its square wave before
switching.")

(defparameter +rainbow-wave-amplitude+ 1
  "How many rows the rainbow's top edge rises on the wave's upper step.")

(defun rainbow-wave-offset (column tick)
  "Return the rows the rainbow's top edge is pushed down at COLUMN at TICK.
The result is 0 on the wave's upper step and +RAINBOW-WAVE-AMPLITUDE+ on the
lower one. TICK enters the same way it does in the starfield -- as a shift of
the world column -- so the wave travels leftwards at exactly the speed the
stars do and the two layers never drift apart."
  (if (evenp (floor (+ column tick) +rainbow-wave-period+))
      0
      +rainbow-wave-amplitude+))

(defun rainbow-band-at (column row cat-x cat-y tick)
  "Return the rainbow band index covering (COLUMN, ROW) at TICK, or NIL.
The trail fills every column left of the cat's own left edge CAT-X, stacking
+RAINBOW-BAND-COUNT+ bands downwards from CAT-Y as displaced by
RAINBOW-WAVE-OFFSET. The band index is counted from 0 at the top, which is what
RAINBOW-BAND-STYLE and RAINBOW-BAND-CHAR take. A cell at or right of CAT-X is
never covered: that is where the cat itself is drawn."
  (when (< column cat-x)
    (let ((band (- row cat-y (rainbow-wave-offset column tick))))
      (and (< -1 band +rainbow-band-count+) band))))
