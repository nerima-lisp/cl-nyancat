;;;; src/geometry.lisp -- sprite text helpers shared by every drawing layer.
;;;;
;;;; Nothing here is nyancat-specific: splitting sprite text into lines,
;;;; measuring it, and finding a line's occupied span are generic operations.
;;;; They live here rather than beside the cat art because render.lisp needs
;;;; SPRITE-ROW-SPAN for the cat's opaque backdrop (see draw-cat) and world.lisp
;;;; needs the dimensions to place the sprite.
(in-package #:cl-nyancat)

(defun clamp (value low high)
  "Return VALUE clamped to the inclusive range [LOW, HIGH]."
  (max low (min high value)))

(defun split-sprite-lines (text)
  "Return TEXT split on #\\Newline as a list of lines.
Mirrors cl-tty-kit's own internal sprite line-splitter, which SPRITE-BLIT
applies to the same text but does not export."
  (loop with start = 0
        with lines = '()
        for newline-position = (position #\Newline text :start start)
        do (push (subseq text start (or newline-position (length text))) lines)
           (if newline-position
               (setf start (1+ newline-position))
               (return (nreverse lines)))))

(defun sprite-dimensions (text)
  "Return (VALUES WIDTH HEIGHT) for multi-line sprite TEXT.
HEIGHT is the number of lines; WIDTH is the length of the longest one. An
empty TEXT is one empty line, so its dimensions are 0 by 1."
  (let ((lines (split-sprite-lines text)))
    (values (reduce #'max lines :key #'length :initial-value 0)
            (length lines))))

(defun sprite-width (text)
  "Return only the WIDTH of SPRITE-DIMENSIONS for sprite TEXT."
  (nth-value 0 (sprite-dimensions text)))

(defun sprite-height (text)
  "Return only the HEIGHT of SPRITE-DIMENSIONS for sprite TEXT."
  (nth-value 1 (sprite-dimensions text)))

(defun sprite-row-span (line)
  "Return (VALUES START END), the half-open span from the first through one
past the last non-space character in LINE. Return 0, 0 when LINE is empty
or all spaces."
  (let ((start (position #\Space line :test #'char/=)))
    (if start
        (values start (1+ (position #\Space line :test #'char/= :from-end t)))
        (values 0 0))))
