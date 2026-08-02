;;;; src/render.lisp -- painting a WORLD onto a cl-tty-kit SCREEN.
;;;;
;;;; Three layers, painted back to front: starfield, rainbow trail, cat. Paint
;;;; order alone establishes the layering -- cl-tty-kit's entity.lisp file
;;;; header calls that out as the intended use of SPRITE-BLIT -- so there is no
;;;; z-buffer and no sorting step.
;;;;
;;;; Nothing here writes to a stream. DRAW-WORLD fills a SCREEN and
;;;; WORLD-TO-STRING reads one back as plain text, which is what lets
;;;; t/render-test.lisp assert on exact painted cells with no terminal
;;;; involved; RENDER-FRAME is the only function that hands work to a RENDERER,
;;;; and even that returns its diff as a string rather than printing it.
(in-package #:cl-nyancat)

(defun %put-cell-clipped (screen x y char style)
  "Write CHAR into SCREEN at (X, Y) with STYLE, ignoring an out-of-bounds cell.
Returns SCREEN. cl-tty-kit's SCREEN-PUT-CELL signals on a cell outside the
grid; every caller below walks a region derived from the cat's position, which
a mid-frame resize can put partly off screen, so the clip belongs here rather
than in four separate bounds tests."
  (when (and (<= 0 x) (< x (screen-width screen))
             (<= 0 y) (< y (screen-height screen)))
    (screen-put-cell screen x y char :style style))
  screen)

(defun draw-stars (screen world)
  "Paint WORLD's starfield over the whole of SCREEN, returning SCREEN.
Every cell is asked STAR-CHAR-AT; the vast majority answer NIL and are left
untouched, so this composites over whatever SCREEN already holds rather than
clearing it."
  (dotimes (y (screen-height screen) screen)
    (dotimes (x (screen-width screen))
      (multiple-value-bind (char phase)
          (star-char-at (world-seed world) x y (world-tick world))
        (when char
          (%put-cell-clipped screen x y char (star-style phase (world-colorp world))))))))

(defun draw-rainbow (screen world)
  "Paint WORLD's rainbow trail onto SCREEN, returning SCREEN.
Only the region the trail can reach is walked -- every column left of the cat,
and the band stack plus the one row RAINBOW-WAVE-OFFSET can push it down --
rather than the whole grid, since the trail covers a fixed slice of it."
  (let ((last-column (min (world-cat-x world) (screen-width screen)))
        (first-row (world-cat-y world))
        (last-row (+ (world-cat-y world) +rainbow-band-count+ +rainbow-wave-amplitude+)))
    (loop for y from (max 0 first-row) below (min last-row (screen-height screen))
          do (dotimes (x last-column)
               (let ((band (rainbow-band-at x y (world-cat-x world) (world-cat-y world)
                                            (world-tick world))))
                 (when band
                   (%put-cell-clipped screen x y
                                      (rainbow-band-char band (world-colorp world))
                                      (rainbow-band-style band (world-colorp world)))))))
    screen))

(defun %blank-cat-silhouette (screen frame cat-x cat-y)
  "Blank the cells FRAME's silhouette occupies at (CAT-X, CAT-Y), returning SCREEN.
SPRITE-BLIT treats every #\\Space as transparent, so without this the starfield
would twinkle through the cat's own body and the rainbow would run straight
across it. Only each row's SPRITE-ROW-SPAN is blanked -- the drawn glyphs and
the blanks enclosed between them -- so the sprite's ragged outline still lets
the background through instead of the cat carrying a rectangular hole around
it."
  (loop for line in (split-sprite-lines frame)
        for row from 0
        do (multiple-value-bind (start end) (sprite-row-span line)
             (loop for column from start below end
                   do (%put-cell-clipped screen (+ cat-x column) (+ cat-y row)
                                         #\Space nil))))
  screen)

(defun draw-cat (screen world)
  "Paint WORLD's current cat frame onto SCREEN, returning SCREEN.
The silhouette is blanked first (see %BLANK-CAT-SILHOUETTE), then the pink
pop-tart body and the grey head are blitted separately: cl-tty-kit's
SPRITE-BLIT applies one style per call, and CAT-FRAME-PART splits the single
authored frame into two same-grid sprites so the two blits reassemble it."
  (let ((frame (world-cat-frame world))
        (x (world-cat-x world))
        (y (world-cat-y world))
        (colorp (world-colorp world)))
    (%blank-cat-silhouette screen frame x y)
    (dolist (part '(:body :head) screen)
      (sprite-blit screen (cat-frame-part frame part) x y
                   :style (cat-style part colorp)))))

(defun draw-world (screen world)
  "Clear SCREEN and paint WORLD's three layers onto it back to front, returning SCREEN."
  (screen-clear screen)
  (draw-stars screen world)
  (draw-rainbow screen world)
  (draw-cat screen world))

(defun world-to-string (world)
  "Return WORLD's current frame as plain text: WORLD-HEIGHT rows joined by newlines.
Styling is dropped, so this is the frame's shape rather than what a terminal
would receive -- which is exactly what a test wants to assert on, and why it
takes no RENDERER and allocates its own SCREEN."
  (let ((screen (make-screen (world-width world) (world-height world))))
    (screen-to-string (draw-world screen world))))

(defun render-frame (renderer world)
  "Draw WORLD onto RENDERER's back buffer and return RENDERER-RENDER's diff output.
The result is the escape-sequence string to write to a terminal to bring it
from the previous frame to this one; it is returned rather than printed, so the
tick loop owns the stream."
  (draw-world (renderer-screen renderer) world)
  (renderer-render renderer))
