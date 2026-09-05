(in-package #:cl-nyancat/test)

(describe "star-hash"
  (it "returns a non-negative 32-bit integer"
    (with-soft-assertions
      (dolist (column '(0 1 17 1000 123456))
        (let ((value (star-hash 3 column 5)))
          (expect (<= 0 value #xFFFFFFFF) :to-be-truthy)))))
  (it "separates the two axes, so (x, y) and (y, x) are not the same cell"
    (expect (= (star-hash 0 3 9) (star-hash 0 9 3)) :to-be-falsy))
  (it "separates seeds, so --seed actually selects a different starfield"
    (expect (= (star-hash 1 10 10) (star-hash 2 10 10)) :to-be-falsy))
  (it "accepts negative coordinates, which a cat near the left edge produces"
    (expect (<= 0 (star-hash 5 -40 -3) #xFFFFFFFF) :to-be-truthy))
  (it-property "is pure and stays within 32 bits for any seed, column and row"
      ((seed (gen-integer :min -100000 :max 100000))
       (column (gen-integer :min -100000 :max 100000))
       (row (gen-integer :min -100000 :max 100000)))
    (with-soft-assertions
      (expect (star-hash seed column row) :to-be (star-hash seed column row))
      (expect (<= 0 (star-hash seed column row) #xFFFFFFFF) :to-be-truthy))))

(describe "star-present-p"
  (it "agrees with itself across calls, with no state carried between them"
    (let ((first-pass (loop for column below 200 collect (star-present-p 9 column 3)))
          (second-pass (loop for column below 200 collect (star-present-p 9 column 3))))
      (expect first-pass :to-equal second-pass)))
  (it "places some stars but not everywhere, over a screen-sized sample"
    (let ((count (loop for column below 400
                       count (star-present-p 0 column 7))))
      (with-soft-assertions
        (expect (plusp count) :to-be-truthy)
        (expect (< count 400) :to-be-truthy))))
  (it "keeps the field sparse rather than crowding out the rainbow"
    ;; Roughly one cell in +STAR-DENSITY+; the bound is loose because this is
    ;; a hash, not a generator with a guaranteed distribution.
    (let ((count (loop for row below 40
                       sum (loop for column below 200
                                 count (star-present-p 4 column row)))))
      (expect (< count (floor (* 200 40) 8)) :to-be-truthy)))
  (it "gives different seeds visibly different fields"
    (let ((first-field (loop for column below 300 collect (star-present-p 1 column 2)))
          (second-field (loop for column below 300 collect (star-present-p 2 column 2))))
      (expect (equal first-field second-field) :to-be-falsy))))

(describe "star-char-at"
  (it "returns nil where the world cell holds no star"
    ;; Find a column that is definitely empty rather than assuming one is.
    (let ((empty (loop for column below 500
                       unless (star-present-p 0 (+ column 0) 1) return column)))
      (expect (star-char-at 0 empty 1 0) :to-be-falsy)))
  (it "returns a twinkle glyph and a phase where the cell holds a star"
    (let ((occupied (loop for column below 500
                          when (star-present-p 0 column 1) return column)))
      (multiple-value-bind (char phase) (star-char-at 0 occupied 1 0)
        (with-soft-assertions
          (expect (characterp char) :to-be-truthy)
          (expect (integerp phase) :to-be-truthy)))))
  (it "only ever returns printable ASCII glyphs"
    ;; CHAR-CODE, not the character itself: see t/palette-test.lisp.
    (let ((chars (loop for column below 300
                       collect (star-char-at 6 column 2 0))))
      (with-soft-assertions
        (expect (some #'characterp chars) :to-be-truthy)
        (expect (every (lambda (char)
                         (or (null char)
                             (< 32 (char-code char) 127)))
                       chars)
                :to-be-truthy))))
  (it "scrolls the field: the cell at column 1 next tick shows what column 0 does now"
    ;; The viewport advances one column per tick, so screen column X at tick T
    ;; and screen column X-1 at tick T+1 name the same world cell. Only the
    ;; presence of a star is compared, since the twinkle phase also advances.
    (with-soft-assertions
      (loop for column from 1 below 120
            do (expect (eq (not (star-char-at 3 column 5 0))
                           (not (star-char-at 3 (1- column) 5 1)))
                       :to-be-truthy))))
  (it "renders a given seed and tick identically on every call"
    (let ((first-frame (loop for column below 120
                             collect (star-char-at 11 column 6 42)))
          (second-frame (loop for column below 120
                              collect (star-char-at 11 column 6 42))))
      (expect first-frame :to-equal second-frame)))
  (it "twinkles: a star can change glyph without moving"
    (let ((changed nil))
      (loop for column from 4 below 300
            for before = (star-char-at 0 column 3 0)
            for after = (star-char-at 0 (- column 4) 3 4)
            when (and before after (char/= before after))
              do (setf changed t))
      (expect changed :to-be-truthy))))
