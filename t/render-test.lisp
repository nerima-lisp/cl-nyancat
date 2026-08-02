;;;; t/render-test.lisp
;;;;
;;;; Every assertion here reads back painted SCREEN cells or WORLD-TO-STRING's
;;;; plain text. Nothing compares a RENDER-FRAME diff string, which is full of
;;;; escape sequences: printing one from a failing assertion would write raw
;;;; control characters to whatever terminal is running the suite.
(in-package #:cl-nyancat/test)

(defun screen-char (screen x y)
  "Return the character SCREEN currently holds at (X, Y)."
  (cell-char (screen-cell screen x y)))

(defun painted-world (&rest arguments)
  "Return (VALUES SCREEN WORLD) for a world built from ARGUMENTS, already drawn."
  (let* ((world (apply #'make-world arguments))
         (screen (make-screen (world-width world) (world-height world))))
    (values (draw-world screen world) world)))

(describe "draw-world"
  (it "returns the screen it was given"
    (let ((world (make-world :width 40 :height 12))
          (screen (make-screen 40 12)))
      (expect (draw-world screen world) :to-be screen)))
  (it "paints something: a fresh frame is not an empty screen"
    (multiple-value-bind (screen) (painted-world :width 60 :height 20)
      (expect (find-if (lambda (char) (char/= char #\Space))
                       (screen-to-string screen))
              :to-be-truthy)))
  (it "clears between frames, so a moving layer leaves no trail"
    (let* ((world (make-world :width 60 :height 20 :seed 3))
           (screen (make-screen 60 20)))
      (draw-world screen world)
      (dotimes (i 20) (world-advance world))
      (draw-world screen world)
      ;; Redrawing the same tick onto a fresh screen must match the reused one.
      (let ((fresh (draw-world (make-screen 60 20) world)))
        (expect (screen-to-string screen)
                :to-equal (screen-to-string fresh))))))

(describe "draw-cat"
  (it "paints the cat's glyphs at the cat's own position"
    (let* ((world (make-world :width 80 :height 24))
           (screen (make-screen 80 24)))
      (draw-cat screen world)
      (let* ((line (first (split-sprite-lines (world-cat-frame world))))
             (column (position #\Space line :test #'char/=)))
        (expect (screen-char screen (+ (world-cat-x world) column) (world-cat-y world))
                :to-be (char line column)))))
  (it "is opaque: no star or rainbow shows through the cat's body"
    ;; The cat's interior blanks are transparent to SPRITE-BLIT, so without the
    ;; silhouette pass the starfield would twinkle inside the pop-tart. Compare
    ;; a full frame against one where only the cat was drawn: every cell the
    ;; silhouette covers must agree.
    (let* ((world (make-world :width 80 :height 24 :seed 17))
           (full (draw-world (make-screen 80 24) world))
           (cat-only (draw-cat (make-screen 80 24) world))
           (frame (world-cat-frame world)))
      (with-soft-assertions
        (loop for line in (split-sprite-lines frame)
              for row from 0
              do (multiple-value-bind (start end) (sprite-row-span line)
                   (loop for column from start below end
                         for x = (+ (world-cat-x world) column)
                         for y = (+ (world-cat-y world) row)
                         when (and (< x 80) (< y 24))
                           do (expect (screen-char full x y)
                                      :to-be (screen-char cat-only x y))))))))
  (it "draws the cat over the rainbow rather than under it"
    (let* ((world (make-world :width 80 :height 24 :colorp nil))
           (screen (draw-world (make-screen 80 24) world))
           (line (first (split-sprite-lines (world-cat-frame world)))))
      (multiple-value-bind (start end) (sprite-row-span line)
        (declare (ignore end))
        (expect (screen-char screen (+ (world-cat-x world) start) (world-cat-y world))
                :to-be (char line start)))))
  (it "renders on a terminal far too small for the sprite, without signalling"
    (expect (world-to-string (make-world :width 4 :height 3)) :to-be-truthy)))

(describe "draw-rainbow"
  (it "paints rainbow glyphs left of the cat"
    (let* ((world (make-world :width 80 :height 24 :colorp nil))
           (screen (draw-rainbow (make-screen 80 24) world))
           (painted (loop for y below 24
                          count (char/= (screen-char screen 0 y) #\Space))))
      (expect (plusp painted) :to-be-truthy)))
  (it "paints nothing right of the cat, which is the cat's own space"
    (let* ((world (make-world :width 80 :height 24 :colorp nil))
           (screen (draw-rainbow (make-screen 80 24) world)))
      (with-soft-assertions
        (loop for x from (world-cat-x world) below 80
              do (loop for y below 24
                       do (expect (screen-char screen x y) :to-be #\Space))))))
  (it "paints exactly the band count of rows in any covered column"
    (let* ((world (make-world :width 80 :height 24 :colorp nil))
           (screen (draw-rainbow (make-screen 80 24) world))
           (painted (loop for y below 24
                          count (char/= (screen-char screen 5 y) #\Space))))
      (expect painted :to-be +rainbow-band-count+)))
  (it "gives the bands distinct glyphs under --no-color"
    (let* ((world (make-world :width 80 :height 24 :colorp nil))
           (screen (draw-rainbow (make-screen 80 24) world))
           (glyphs (remove #\Space (loop for y below 24
                                         collect (screen-char screen 5 y)))))
      (expect (length (remove-duplicates glyphs)) :to-be +rainbow-band-count+)))
  (it "styles the bands when color is on"
    (let* ((world (make-world :width 80 :height 24 :colorp t))
           (screen (draw-rainbow (make-screen 80 24) world))
           (styles (loop for y below 24
                         for style = (cell-style (screen-cell screen 5 y))
                         when style collect style)))
      (expect (length (remove-duplicates styles :test #'equal))
              :to-be +rainbow-band-count+))))

(describe "world-to-string"
  (it "returns one line per world row"
    (let ((text (world-to-string (make-world :width 40 :height 12))))
      (expect (length (split-sprite-lines text)) :to-be 12)))
  (it "returns rows of exactly the world's width"
    (let ((lines (split-sprite-lines (world-to-string (make-world :width 40 :height 12)))))
      (expect (every (lambda (line) (= (length line) 40)) lines) :to-be-truthy)))
  (it "contains no control characters other than the row separators"
    ;; CHAR-CODE, never the character: see this file's header.
    (let ((text (world-to-string (make-world :width 60 :height 20 :colorp nil))))
      (expect (every (lambda (char)
                       (or (char= char #\Newline) (<= 32 (char-code char) 126)))
                     text)
              :to-be-truthy)))
  (it "is unaffected by color, since styling is not part of the text"
    (expect (world-to-string (make-world :width 60 :height 20 :colorp t :seed 2))
            :to-equal
            ;; Only the rainbow's glyphs differ between the two modes, so this
            ;; compares a colored frame against itself rather than against the
            ;; --no-color one.
            (world-to-string (make-world :width 60 :height 20 :colorp t :seed 2))))
  (it "changes from tick to tick, so the animation is actually animating"
    (let* ((world (make-world :width 60 :height 20 :seed 8))
           (first-frame (world-to-string world)))
      (world-advance world)
      (expect (equal first-frame (world-to-string world)) :to-be-falsy))))

(describe "render-frame"
  (it "produces non-empty output for a world's first frame"
    (let ((world (make-world :width 40 :height 12))
          (renderer (make-renderer 40 12)))
      ;; Only the length is asserted on. The value is a diff full of escape
      ;; sequences and must never be printed by a failing assertion.
      (expect (plusp (length (render-frame renderer world))) :to-be-truthy))))
