;;;; src/art-cat.lisp -- the cat sprite as ASCII art.
;;;;
;;;; Both frames share one column grid. CAT-FRAME-PART uses that grid to split
;;;; each frame into its pink body and grey head:
;;;;
;;;;     columns  0-1    the tail, which drops one row between frames
;;;;     columns  2-15   the pop-tart body
;;;;     column   16     always blank; the seam CAT-FRAME-PART cuts on
;;;;     columns 17-23   the head
;;;;
;;;; The two frames differ in the tail, paws, and sprinkle rows.
(in-package #:cl-nyancat)

(defparameter +cat-head-column+ 16
  "The first column of the cat sprite that belongs to the head rather than the
pop-tart body. See CAT-FRAME-PART and the file header's column map.")

(defparameter +cat-frame-ticks+ 4
  "How many ticks each cat animation frame is held for.")

(defparameter +cat-frames+
  (map 'vector
       (lambda (rows) (format nil "~{~A~^~%~}" rows))
       ;; Authored as one list of rows per frame rather than one ~%-separated
       ;; format string, so the column grid the file header describes is
       ;; readable as a grid in the source too.
       (list
        ;; Frame 0: tail up, paws planted.
        (list "  ,------------,  /\\_/\\"
              "  | . * . * .  | ( -.- )"
              "~~| * . * . *  | (  w  )"
              "  | . * . * .  |  \\___/"
              "  | * . * . *  |"
              "  '------------'"
              "    ''      ''")
        ;; Frame 1: tail down, paws swung forward, sprinkle rows shifted.
        (list "  ,------------,  /\\_/\\"
              "  | * . * . *  | ( -.- )"
              "  | . * . * .  | (  w  )"
              "~~| * . * . *  |  \\___/"
              "  | . * . * .  |"
              "  '------------'"
              "    ,,      ,,")))
  "The cat's animation frames, in cycle order. See the file header for the
column grid both frames share.")

(defparameter +cat-frame-count+ (length +cat-frames+)
  "How many animation frames the cat sprite cycles through.")

(defun cat-frame (index)
  "Return the cat's animation frame INDEX as multi-line sprite text.
INDEX is taken modulo +CAT-FRAME-COUNT+, so a caller counting frames upward
never has to wrap it itself."
  (aref +cat-frames+ (mod index +cat-frame-count+)))

(defun cat-frame-for-tick (tick)
  "Return the cat animation frame index to draw at TICK.
Each frame is held for +CAT-FRAME-TICKS+ ticks before the next one; the result
is always a valid index into +CAT-FRAMES+."
  (mod (floor tick +cat-frame-ticks+) +cat-frame-count+))

(defun %blank-outside-part (line part)
  "Return LINE with every column not belonging to PART replaced by a blank.
PART is :BODY for columns before +CAT-HEAD-COLUMN+ and :HEAD for the rest."
  (let ((result (copy-seq line)))
    (dotimes (column (length result) result)
      (unless (eq part (if (< column +cat-head-column+) :body :head))
        (setf (char result column) #\Space)))))

(defun cat-frame-part (text part)
  "Return sprite TEXT with only PART's columns kept, the rest blanked.
PART is :BODY or :HEAD. Both results keep the original column grid, so blitting
them at the same position reassembles the whole cat -- which is how the pink
tart and the grey head get separate styles out of one authored frame, since
cl-tty-kit's SPRITE-BLIT applies a single style per call. A blanked column is a
#\\Space and therefore transparent, so the two blits do not erase each other."
  (format nil "~{~A~^~%~}"
          (mapcar (lambda (line) (%blank-outside-part line part))
                  (split-sprite-lines text))))

(defun cat-art-width ()
  "Return the width in columns of the cat sprite's widest animation frame."
  (reduce #'max +cat-frames+ :key #'sprite-width :initial-value 0))

(defun cat-art-height ()
  "Return the height in rows of the cat sprite's tallest animation frame."
  (reduce #'max +cat-frames+ :key #'sprite-height :initial-value 0))
