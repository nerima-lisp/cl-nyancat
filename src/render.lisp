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

(defun draw-stars (screen world &key (x-offset 0) (y-offset 0) (viewport-width (screen-width screen)) (viewport-height (screen-height screen))) "Paint the WORLD starfield into the visible viewport, returning SCREEN. X-OFFSET and Y-OFFSET map viewport coordinates back to world coordinates." (dotimes (y viewport-height screen) (dotimes (x viewport-width) (multiple-value-bind (char phase) (star-char-at (world-seed world) (+ x x-offset) (+ y y-offset) (world-tick world)) (when char (%put-cell-clipped screen x y char (star-style phase (world-colorp world))))))))

(defun draw-rainbow (screen world &key (x-offset 0) (y-offset 0) (viewport-width (screen-width screen)) (viewport-height (screen-height screen))) "Paint the WORLD rainbow into the visible viewport, returning SCREEN. Rainbow coordinates stay in world space while X-OFFSET and Y-OFFSET project them into the viewport." (let* ((cat-x (- (world-cat-x world) x-offset)) (cat-y (- (world-cat-y world) y-offset)) (last-column (min (max 0 cat-x) viewport-width)) (first-row cat-y) (last-row (+ cat-y +rainbow-band-count+ +rainbow-wave-amplitude+))) (loop for y from (max 0 first-row) below (min last-row viewport-height) do (dotimes (x last-column) (let ((band (rainbow-band-at (+ x x-offset) (+ y y-offset) (world-cat-x world) (world-cat-y world) (world-tick world)))) (when band (%put-cell-clipped screen x y (rainbow-band-char band (world-colorp world)) (rainbow-band-style band (world-colorp world))))))) screen))

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

(defun %draw-cat-part (screen frame x y part colorp)
  "Paint one FRAME PART at (X, Y), applying its optional COLORP style."
  (sprite-blit screen (cat-frame-part frame part) x y
               :style (cat-style part colorp))
  screen)

(defun draw-cat (screen world &key (x-offset 0) (y-offset 0)) "Paint the WORLD cat into the visible viewport, returning SCREEN. The cat remains in world coordinates and the offsets project it into local screen coordinates." (let ((frame (world-cat-frame world)) (x (- (world-cat-x world) x-offset)) (y (- (world-cat-y world) y-offset)) (colorp (world-colorp world))) (%blank-cat-silhouette screen frame x y) (dolist (part (quote (:body :head)) screen) (%draw-cat-part screen frame x y part colorp))))

(defun %viewport-bounds (screen world min-cols max-cols min-rows max-rows) "Return the clamped source origin and visible size for a WORLD viewport on SCREEN. MAX-COLS and MAX-ROWS are exclusive source bounds." (check-type min-cols (integer 0 *)) (check-type min-rows (integer 0 *)) (when max-cols (check-type max-cols (integer 0 *))) (when max-rows (check-type max-rows (integer 0 *))) (let* ((world-width (world-width world)) (world-height (world-height world)) (left (min world-width min-cols)) (top (min world-height min-rows)) (right (min world-width (or max-cols world-width))) (bottom (min world-height (or max-rows world-height))) (right (max left right)) (bottom (max top bottom))) (values left top (min (screen-width screen) (- right left)) (min (screen-height screen) (- bottom top)))))
(defun draw-world (screen world &key (min-cols 0) max-cols (min-rows 0) max-rows) "Clear SCREEN and paint the requested WORLD viewport from back to front, returning SCREEN. Crop maxima are exclusive source bounds." (multiple-value-bind (x-offset y-offset viewport-width viewport-height) (%viewport-bounds screen world min-cols max-cols min-rows max-rows) (screen-clear screen) (draw-stars screen world :x-offset x-offset :y-offset y-offset :viewport-width viewport-width :viewport-height viewport-height) (draw-rainbow screen world :x-offset x-offset :y-offset y-offset :viewport-width viewport-width :viewport-height viewport-height) (draw-cat screen world :x-offset x-offset :y-offset y-offset)))

(defun world-to-string (world)
  "Return WORLD's current frame as plain text: WORLD-HEIGHT rows joined by newlines.
Styling is dropped, so this is the frame's shape rather than what a terminal
would receive -- which is exactly what a test wants to assert on, and why it
takes no RENDERER and allocates its own SCREEN."
  (let ((screen (make-screen (world-width world) (world-height world))))
    (screen-to-string (draw-world screen world))))

(defun render-frame (renderer world &key (counterp nil) (fps 12) (clearp nil) (min-cols 0) max-cols (min-rows 0) max-rows) "Draw WORLD onto RENDERER back buffer and return terminal escape sequences. COUNTERP overlays an elapsed-frame counter. MIN-COLS, MAX-COLS, MIN-ROWS and MAX-ROWS project a source viewport onto the renderer. When CLEARP is true, invalidate the renderer and prepend a full-screen clear; when false, return the renderer diff so callers can use incremental repainting." (let ((screen (renderer-screen renderer))) (draw-world screen world :min-cols min-cols :max-cols max-cols :min-rows min-rows :max-rows max-rows) (when counterp (check-type fps (integer 1 *)) (let ((counter (format nil "TIME: ~D" (floor (world-tick world) fps)))) (screen-write-string screen 0 0 counter :end (min (length counter) (screen-width screen))))) (when clearp (renderer-invalidate renderer)) (let ((output (renderer-render renderer))) (if clearp (concatenate (quote string) (ansi-clear-screen) (ansi-move-cursor 1 1) output) output))))
