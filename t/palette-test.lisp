(in-package #:cl-nyancat/test)

(describe "rainbow-band-style"
  (it "returns a style for every valid band when color is on"
    (with-soft-assertions
      (dotimes (band +rainbow-band-count+)
        (expect (rainbow-band-style band t) :to-be-truthy))))
  (it "returns nil for every valid band when color is off"
    (with-soft-assertions
      (dotimes (band +rainbow-band-count+)
        (expect (rainbow-band-style band nil) :to-be-falsy))))
  (it "gives the six bands six distinct styles, so the rainbow is not one flat color"
    (let ((styles (loop for band below +rainbow-band-count+
                        collect (rainbow-band-style band t))))
      (expect (length (remove-duplicates styles :test #'equal))
              :to-be +rainbow-band-count+)))
  (it "rejects a band index below zero"
    (signals nyancat-invalid-band (rainbow-band-style -1 t)))
  (it "rejects a band index at the count, which is one past the last band"
    (signals nyancat-invalid-band (rainbow-band-style +rainbow-band-count+ t)))
  (it "rejects a non-integer band index"
    (signals nyancat-invalid-band (rainbow-band-style :red t))))

(describe "rainbow-band-char"
  (it "uses one shared glyph for every band when color carries the distinction"
    (let ((chars (loop for band below +rainbow-band-count+
                       collect (rainbow-band-char band t))))
      (expect (length (remove-duplicates chars)) :to-be 1)))
  (it "gives every band its own glyph when there is no color to tell them apart"
    (let ((chars (loop for band below +rainbow-band-count+
                       collect (rainbow-band-char band nil))))
      (expect (length (remove-duplicates chars)) :to-be +rainbow-band-count+)))
  (it "only ever returns printable ASCII, so a --no-color frame is plain text"
    ;; Compare by CHAR-CODE rather than printing control characters.
    (with-soft-assertions
      (dotimes (band +rainbow-band-count+)
        (expect (< 32 (char-code (rainbow-band-char band nil)) 127) :to-be-truthy)
        (expect (< 32 (char-code (rainbow-band-char band t)) 127) :to-be-truthy))))
  (it "rejects an out-of-range band index"
    (signals nyancat-invalid-band (rainbow-band-char 99 nil))))

(describe "star-style"
  (it "returns a style when color is on"
    (expect (star-style 0 t) :to-be-truthy))
  (it "returns nil when color is off"
    (expect (star-style 0 nil) :to-be-falsy))
  (it "alternates between a bright and a dim entry as the phase advances"
    (expect (equal (star-style 0 t) (star-style 1 t)) :to-be-falsy))
  (it "repeats once the phase wraps the palette"
    (expect (star-style 0 t) :to-equal (star-style 2 t)))
  (it "accepts any phase, including one past the twinkle cycle's own length"
    (expect (star-style 97 t) :to-be-truthy)))

(describe "cat-style"
  (it "gives the body and the head different colors"
    (expect (equal (cat-style :body t) (cat-style :head t)) :to-be-falsy))
  (it "returns nil for both parts when color is off"
    (with-soft-assertions
      (expect (cat-style :body nil) :to-be-falsy)
      (expect (cat-style :head nil) :to-be-falsy)))
  (it "returns nil for an unrecognized part rather than signalling"
    (expect (cat-style :tail t) :to-be-falsy)))
