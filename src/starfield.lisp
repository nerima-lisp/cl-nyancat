;;;; src/starfield.lisp -- the scrolling starfield, as a pure function.
;;;;
;;;; There is no *RANDOM-STATE* anywhere in this file, and that is the point.
;;;; cl-asciiquarium seeds a generator and then walks it, which makes a frame
;;;; reproducible only by replaying every draw that came before it. Here a star
;;;; is a pure function of (SEED, world column, row): STAR-PRESENT-P can be
;;;; asked about frame 10,000 without computing frames 0 through 9,999, tests
;;;; can assert on a single cell, and two runs with the same --seed are
;;;; byte-identical by construction rather than by discipline.
;;;;
;;;; Scrolling falls out of the same property. The starfield is fixed in world
;;;; space and the viewport moves right one column per tick, so screen column X
;;;; at tick T shows world column X + T -- which is why the cat can sit still
;;;; and still read as flying.
(in-package #:cl-nyancat)

(defparameter +star-density+ 29
  "One world cell in this many carries a star.")

(defparameter +star-chars+ #(#\. #\+ #\* #\+)
  "The twinkle cycle a star steps through, one entry per +STAR-PHASE-TICKS+.")

(defparameter +star-phase-ticks+ 3
  "How many ticks a star holds each entry of +STAR-CHARS+.")

(defun star-hash (seed column row)
  "Return a well-mixed non-negative 32-bit integer for the world cell (COLUMN, ROW) under SEED.
This is the lowbias32 integer finalizer over the three coordinates combined by
large odd multipliers -- a hash, not a random number generator: the same
arguments always give the same result, in any image, in any order, with no
state carried between calls. COLUMN and ROW may be negative."
  (let ((x (logand (+ (* column 73856093) (* row 19349663) (* seed 83492791))
                   #xFFFFFFFF)))
    (setf x (logand (* (logxor x (ash x -16)) #x7FEB352D) #xFFFFFFFF))
    (setf x (logand (* (logxor x (ash x -15)) #x846CA68B) #xFFFFFFFF))
    (logxor x (ash x -16))))

(defun star-present-p (seed column row)
  "True when the world cell (COLUMN, ROW) holds a star under SEED.
Roughly one cell in +STAR-DENSITY+ does."
  (zerop (mod (star-hash seed column row) +star-density+)))

(defun star-char-at (seed screen-column row tick)
  "Return (VALUES CHAR PHASE) for the star visible at SCREEN-COLUMN and ROW at TICK, or NIL.
The world column shown at SCREEN-COLUMN is SCREEN-COLUMN + TICK, which is what
makes the field scroll leftwards past a stationary cat. When that world cell
holds no star the primary value is NIL and there is no second value; otherwise
CHAR is its current twinkle glyph and PHASE the counter STAR-STYLE reads to
pick a brightness. Each star starts at its own point in the cycle, taken from
its hash, so the field does not pulse in unison."
  (let* ((column (+ screen-column tick))
         (hash (star-hash seed column row)))
    (when (zerop (mod hash +star-density+))
      (let ((phase (mod (+ (floor tick +star-phase-ticks+)
                           hash)
                        (length +star-chars+))))
        (values (aref +star-chars+ phase) phase)))))
