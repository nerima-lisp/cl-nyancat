;;;; src/palette.lisp -- every color and glyph the three drawing layers use.
;;;;
;;;; Colors are kept here rather than beside the layer that draws them so that
;;;; --no-color has exactly one place to answer for. Each accessor below takes
;;;; the world's COLORP flag and returns NIL for the plain-ASCII mode, which is
;;;; also what SPRITE-BLIT and SCREEN-PUT-CELL take to mean "unstyled" -- so no
;;;; caller needs a branch of its own.
;;;;
;;;; The indices are 256-color palette entries, which is what cl-tty-kit's
;;;; STYLE-FG accepts as a lone byte. The 8/16-color set has no orange, and
;;;; nyancat's rainbow is unmistakably red-orange-yellow rather than
;;;; red-yellow, so the wider palette is load-bearing here rather than a
;;;; gratuitous upgrade.
(in-package #:cl-nyancat)

(defparameter +rainbow-band-count+ 6
  "How many horizontal color bands the rainbow trail is made of.")

(defparameter +rainbow-band-colors+ #(196 208 226 46 33 93)
  "The 256-color index of each rainbow band, top to bottom: red, orange,
yellow, green, blue, violet.")

(defparameter +rainbow-band-plain-chars+ #(#\- #\= #\~ #\+ #\* #\#)
  "The glyph each rainbow band is drawn with under --no-color. A terminal
without color has nothing else to tell the six bands apart, so each gets a
distinct character; with color they all share +RAINBOW-BAND-COLOR-CHAR+ and
read as one solid ribbon.")

(defparameter +rainbow-band-color-char+ #\=
  "The glyph every rainbow band is drawn with when color is available.")

(defparameter +star-colors+ #(15 250)
  "The 256-color index of a bright and a dim star, indexed by STAR-CHAR-AT's
own phase parity so the starfield twinkles in brightness as well as in shape.")

(defparameter +cat-part-colors+ '((:body . 218) (:head . 250))
  "The 256-color index of each region of the cat sprite: a pink pop-tart body
and a grey head. SPRITE-BLIT applies one style per call, so render.lisp blits
the two regions separately -- see CAT-FRAME-PART.")

(defun %assert-band (index)
  "Return INDEX, or signal NYANCAT-INVALID-BAND when it is not a valid band."
  (unless (and (integerp index) (< -1 index +rainbow-band-count+))
    (error 'nyancat-invalid-band :index index))
  index)

(defun rainbow-band-style (index colorp)
  "Return the cl-tty-kit style for rainbow band INDEX, or NIL when COLORP is false.
INDEX is counted from 0 at the top band. An INDEX outside
[0, +RAINBOW-BAND-COUNT+) signals NYANCAT-INVALID-BAND."
  (%assert-band index)
  (and colorp (make-style (style-fg (aref +rainbow-band-colors+ index)))))

(defun rainbow-band-char (index colorp)
  "Return the character rainbow band INDEX is drawn with.
With COLORP true every band shares one glyph and the color carries the
distinction; without it each band gets its own glyph. An INDEX outside
[0, +RAINBOW-BAND-COUNT+) signals NYANCAT-INVALID-BAND."
  (%assert-band index)
  (if colorp
      +rainbow-band-color-char+
      (aref +rainbow-band-plain-chars+ index)))

(defun star-style (phase colorp)
  "Return the cl-tty-kit style for a star at animation PHASE, or NIL when COLORP is false.
PHASE is STAR-CHAR-AT's own phase counter; only its parity is read, so a star
alternates between the two entries of +STAR-COLORS+ as it twinkles."
  (and colorp
       (make-style (style-fg (aref +star-colors+ (mod phase (length +star-colors+)))))))

(defun cat-style (part colorp)
  "Return the cl-tty-kit style for the cat sprite's PART, or NIL when COLORP is false.
PART is :BODY or :HEAD. An unrecognized PART is unstyled rather than an error:
the renderer can therefore skip styling parts without a palette entry."
  (let ((color (cdr (assoc part +cat-part-colors+))))
    (and colorp color (make-style (style-fg color)))))
