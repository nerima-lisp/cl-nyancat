(in-package #:cl-nyancat/test)

(describe "the cat sprite's frames"
  (it "has at least two frames, or nothing would animate"
    (expect (>= +cat-frame-count+ 2) :to-be-truthy))
  (it "gives every frame the same height, so the cat does not jump between frames"
    (let ((heights (loop for index below +cat-frame-count+
                         collect (sprite-height (cat-frame index)))))
      (expect (length (remove-duplicates heights)) :to-be 1)))
  (it "draws consecutive frames differently, so the animation is visible"
    (expect (string= (cat-frame 0) (cat-frame 1)) :to-be-falsy))
  (it "wraps an index past the last frame back to the first"
    (expect (cat-frame +cat-frame-count+) :to-equal (cat-frame 0)))
  (it "is drawn entirely in printable ASCII"
    ;; Compare by CHAR-CODE rather than printing control characters.
    (with-soft-assertions
      (dotimes (index +cat-frame-count+)
        (expect (every (lambda (char)
                         (or (char= char #\Newline)
                             (<= 32 (char-code char) 126)))
                       (cat-frame index))
                :to-be-truthy))))
  (it "reports a width and height matching the art it actually holds"
    (with-soft-assertions
      (expect (cat-art-width) :to-be (sprite-width (cat-frame 0)))
      (expect (cat-art-height) :to-be (sprite-height (cat-frame 0)))))
  (it "leaves room below the pop-tart rows for the rainbow's band stack"
    ;; The rainbow hangs +RAINBOW-BAND-COUNT+ rows from the sprite's own top,
    ;; so a cat shorter than that would trail a ribbon taller than itself.
    (expect (>= (cat-art-height) +rainbow-band-count+) :to-be-truthy)))

(describe "cat-frame-for-tick"
  (it "starts on frame 0"
    (expect (cat-frame-for-tick 0) :to-be 0))
  (it "holds one frame for several consecutive ticks rather than flickering"
    (expect (cat-frame-for-tick 0) :to-be (cat-frame-for-tick 1)))
  (it "eventually advances to the next frame"
    (expect (find-if (lambda (tick) (/= (cat-frame-for-tick tick) 0))
                     (loop for tick below 64 collect tick))
            :to-be-truthy))
  (it "always returns a valid frame index, however far the tick has run"
    (with-soft-assertions
      (dolist (tick '(0 1 7 100 4095 99999))
        (expect (< -1 (cat-frame-for-tick tick) +cat-frame-count+) :to-be-truthy))))
  (it "cycles rather than growing without bound"
    (let ((seen (remove-duplicates (loop for tick below 512
                                         collect (cat-frame-for-tick tick)))))
      (expect (length seen) :to-be +cat-frame-count+))))

(describe "cat-frame-part"
  (it "keeps the two parts on the original column grid, so they reassemble"
    (let ((frame (cat-frame 0)))
      (with-soft-assertions
        (expect (sprite-height (cat-frame-part frame :body))
                :to-be (sprite-height frame))
        (expect (sprite-height (cat-frame-part frame :head))
                :to-be (sprite-height frame)))))
  (it "puts every glyph in exactly one of the two parts"
    (let* ((frame (cat-frame 0))
           (body (cat-frame-part frame :body))
           (head (cat-frame-part frame :head)))
      (expect (loop for index below (length frame)
                    always (let ((original (char frame index)))
                             (or (char= original #\Space)
                                 (char= original #\Newline)
                                 (char= original (char body index))
                                 (char= original (char head index)))))
              :to-be-truthy)))
  (it "never puts the same glyph in both parts"
    (let* ((frame (cat-frame 0))
           (body (cat-frame-part frame :body))
           (head (cat-frame-part frame :head)))
      (expect (loop for index below (length frame)
                    never (and (char/= (char body index) #\Space)
                               (char/= (char head index) #\Space)
                               (char/= (char body index) #\Newline)))
              :to-be-truthy)))
  (it "leaves neither part empty, or one of the two blits would be wasted"
    (let ((frame (cat-frame 0)))
      (with-soft-assertions
        (expect (find-if #'graphic-char-p
                         (remove #\Space (cat-frame-part frame :body)))
                :to-be-truthy)
        (expect (find-if #'graphic-char-p
                         (remove #\Space (cat-frame-part frame :head)))
                :to-be-truthy))))
  (it-property "recomposing the two parts reproduces the original frame"
      ((index (gen-integer :min 0 :max (1- +cat-frame-count+))))
    ;; Recombining the non-blank character at each position must reproduce FRAME.
    (let* ((frame (cat-frame index))
           (body (cat-frame-part frame :body))
           (head (cat-frame-part frame :head)))
      (expect (map 'string
                   (lambda (body-char head-char)
                     (if (char= body-char #\Space) head-char body-char))
                   body head)
              :to-equal frame))))
