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
      (multiple-value-bind (source-char phase)
          (star-char-at (world-seed world) x y (world-tick world))
        (when source-char
          (%put-cell-clipped screen x y source-char (star-style phase (world-colorp world))))))))

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

(defparameter +nyancat-color-map+
  '((#\, . 17) (#\. . 231) (#\' . 16) (#\@ . 230)
    (#\$ . 175) (#\- . 162) (#\> . 196) (#\& . 214)
    (#\+ . 226) (#\# . 118) (#\= . 33) (#\; . 19)
    (#\* . 240) (#\% . 175)))

(defparameter +nyancat-glyph-map+
  '((#\, . #\.) (#\. . #\@) (#\' . #\Space) (#\@ . #\#)
    (#\$ . #\?) (#\- . #\O) (#\> . #\#) (#\& . #\=)
    (#\+ . #\-) (#\# . #\+) (#\= . #\~) (#\; . #\$)
    (#\* . #\;) (#\% . #\o)))

(defparameter +nyancat-rainbow-tail+ ",,>>&&&+++###==;;;,,")

(defparameter +nyancat-ansi16-color-map+ (list (cons #\, 104) (cons #\. 107) (cons #\' 40) (cons #\@ 47) (cons #\$ 105) (cons #\- 101) (cons #\> 101) (cons #\& 43) (cons #\+ 103) (cons #\# 102) (cons #\= 104) (cons #\; 44) (cons #\* 100) (cons #\% 105)))

(defparameter *nyancat-terminal-mode* :xterm-256)

(defun %nyancat-terminal-mode (&optional (term (uiop:getenv "TERM"))) (let ((term (string-downcase (or term "")))) (cond ((or (search "xterm" term) (search "toaru" term) (search "rxvt-256color" term) (and (>= (length term) 2) (char= (char term 0) #\s) (char= (char term 1) #\t))) :xterm-256) (t :ansi-16))))

(defun %render-nyancat-terminal-frame-for-cli (world) (let ((*nyancat-terminal-mode* (%nyancat-terminal-mode))) (render-nyancat-terminal-frame world)))

(defun %nyancat-bounds-for-size (width height world)
  "Return WORLD's source frame bounds for a terminal of WIDTH by HEIGHT."
  (multiple-value-bind (min-col max-col)
      (if (and (null (world-min-col world)) (null (world-max-col world)))
          (let ((frame-width (floor width 2)))
            (values (truncate (- +nyancat-frame-width+ frame-width) 2)
                    (truncate (+ +nyancat-frame-width+ frame-width) 2)))
          (values (or (world-min-col world) 0)
                  (or (world-max-col world) +nyancat-frame-width+)))
    (multiple-value-bind (min-row max-row)
        (if (and (null (world-min-row world)) (null (world-max-row world)))
            (let ((frame-height (max 0 (1- height))))
              (values (truncate (- +nyancat-frame-height+ frame-height) 2)
                      (truncate (+ +nyancat-frame-height+ frame-height) 2)))
            (values (or (world-min-row world) 0)
                    (or (world-max-row world) +nyancat-frame-height+)))
      (values min-col max-col min-row max-row))))

(defun %nyancat-bounds (screen world)
  "Return the source frame bounds for WORLD's terminal-sized viewport."
  (%nyancat-bounds-for-size (screen-width screen) (screen-height screen) world))

(defun %nyancat-source-char (frame-index x y)
  "Return the upstream source character at frame coordinates X and Y."
  (cond
    ((and (> y 23) (< y 43) (< x 0))
     (let* ((mod-x (floor (mod (+ (- x) 2) 16) 8))
            (mod-x (if (oddp (floor frame-index 2))
                       (- 1 mod-x)
                       mod-x))
            (tail-index (+ mod-x (- y 23))))
       (or (and (<= 0 tail-index)
                (< tail-index (length +nyancat-rainbow-tail+))
                (char +nyancat-rainbow-tail+ tail-index))
           #\,)))
    ((or (< x 0) (< y 0)
         (>= x +nyancat-frame-width+)
         (>= y +nyancat-frame-height+))
     #\,)
    (t
     (char (nyancat-frame-row frame-index y) x))))

(defun %nyancat-style (source-char colorp)
  (when colorp
    (make-style (style-bg (or (cdr (assoc source-char +nyancat-color-map+))
                              17)))))

(defun %nyancat-glyph (source-char colorp)
  (if colorp
      #\Space
      (or (cdr (assoc source-char +nyancat-glyph-map+)) #\Space)))

(defun %draw-nyancat-counter (screen world row)
  "Paint the deterministic equivalent of nyancat's elapsed-time counter."
  (when (and (<= 0 row) (< row (screen-height screen)))
    (dotimes (x (screen-width screen))
      (%put-cell-clipped screen x row #\Space nil))
    (let* ((seconds (floor (max 0 (1- (world-tick world)))
                           (world-frame-rate world)))
           (text (format nil "You have nyaned for ~D seconds!" seconds))
           (start (floor (- (screen-width screen) (length text)) 2))
           (style (and (world-colorp world)
                       (make-style (style-fg 15) (style-bg 17)))))
      (loop for char across text
            for x from start
            do (%put-cell-clipped screen x row char style))))
  screen)

(defun draw-nyancat-frame (screen world)
  "Paint one upstream-compatible nyancat frame onto SCREEN."
  (when (world-clear-screen-p world)
    (screen-clear screen))
  (multiple-value-bind (min-col max-col min-row max-row)
      (%nyancat-bounds screen world)
    (let ((frame-index (mod (max 0 (1- (world-tick world)))
                            +nyancat-frame-count+)))
      (loop for source-y from min-row below max-row
            for screen-y from 0
            do (loop for source-x from min-col below max-col
                     for screen-x from 0 by 2
                     do (let* ((source-char
                                 (%nyancat-source-char frame-index source-x source-y))
                               (style (%nyancat-style source-char
                                                       (world-colorp world)))
                               (glyph (%nyancat-glyph source-char
                                                      (world-colorp world))))
                          (%put-cell-clipped screen screen-x screen-y glyph style)
                          (%put-cell-clipped screen (1+ screen-x) screen-y glyph style))))
      (when (world-show-counter-p world)
        (%draw-nyancat-counter screen world (- max-row min-row)))))
  screen)

(defun render-nyancat-frame (renderer world)
  "Draw an upstream-compatible frame and return RENDERER's terminal diff."
  (draw-nyancat-frame (renderer-screen renderer) world)
  (renderer-render renderer))

(defun %nyancat-color-escape (source-char) (if (eq *nyancat-terminal-mode* :xterm-256) (format nil "~C[48;5;~Dm" (code-char 27) (or (cdr (assoc source-char +nyancat-color-map+)) 17)) (format nil "~C[~Dm" (code-char 27) (or (cdr (assoc source-char +nyancat-ansi16-color-map+)) 104))))

(defun %nyancat-counter-seconds (world)
  (floor (max 0 (1- (world-tick world)))
         (world-frame-rate world)))

(defun render-nyancat-terminal-frame (world)
  "Return one frame using the ANSI output sequence emitted by nyancat."
  (with-output-to-string (stream)
    (multiple-value-bind (min-col max-col min-row max-row)
        (%nyancat-bounds-for-size (world-width world) (world-height world) world)
      (let* ((frame-index (mod (max 0 (1- (world-tick world)))
                               +nyancat-frame-count+))
             (last-color nil))
        (loop for source-y from min-row below max-row
              do (loop for source-x from min-col below max-col
                       do (let ((source-char
                                  (%nyancat-source-char frame-index source-x source-y)))
                            (when (and (world-colorp world)
                                       (not (eql source-char last-color)))
                              (write-string (%nyancat-color-escape source-char) stream)
                              (setf last-color source-char))
                            (if (world-colorp world)
                                (write-string "  " stream)
                                (let ((glyph (%nyancat-glyph source-char nil)))
                                  (write-char glyph stream)
                                  (write-char glyph stream)))))
                  (write-char #\Return stream)
                  (write-char #\Newline stream))
        (when (world-show-counter-p world)
          (let* ((seconds (%nyancat-counter-seconds world))
                 (digits (length (format nil "~D" seconds)))
                 (padding (max 0 (floor (- (world-width world) 29 digits) 2))))
            (dotimes (index padding)
              (declare (ignore index))
              (write-char #\Space stream))
            (format stream "~C[1;37mYou have nyaned for ~D seconds!~C[J~C[0m"
                    (code-char 27) seconds (code-char 27) (code-char 27))))))))

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
