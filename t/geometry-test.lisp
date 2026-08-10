(in-package #:cl-nyancat/test)

(describe "clamp"
  (it "returns the value unchanged when it is already inside the range"
    (expect (clamp 5 0 10) :to-be 5))
  (it "raises a value below the low bound"
    (expect (clamp -3 0 10) :to-be 0))
  (it "lowers a value above the high bound"
    (expect (clamp 42 0 10) :to-be 10))
  (it "returns the shared bound when low and high are equal"
    (expect (clamp 7 3 3) :to-be 3))
  (it-property "always lands inside [low, high] for any value, low and high"
      ((low (gen-integer :min -10000 :max 10000))
       (spread (gen-integer :min 0 :max 20000))
       (value (gen-integer :min -20000 :max 20000)))
    ;; SPREAD is generated non-negative and added to LOW rather than
    ;; generating HIGH directly and discarding the run when HIGH < LOW:
    ;; TEST_STANDARD.md bans GEN-SUCH-THAT for that kind of filtering, since a
    ;; predicate a random pair rarely satisfies can make a run not terminate.
    (let ((high (+ low spread)))
      (expect (<= low (clamp value low high) high) :to-be-truthy))))

(describe "split-sprite-lines"
  (it "returns a single line for text with no newline"
    (expect (split-sprite-lines "abc") :to-equal '("abc")))
  (it "splits on every newline"
    (expect (split-sprite-lines "ab
cd
ef")
            :to-equal '("ab" "cd" "ef")))
  (it "keeps a trailing empty line, so a sprite's height counts it"
    (expect (split-sprite-lines "ab
") :to-equal '("ab" "")))
  (it "returns one empty line for empty text"
    (expect (split-sprite-lines "") :to-equal '(""))))

(describe "sprite-dimensions"
  (it "reports the longest line as the width and the line count as the height"
    (multiple-value-bind (width height) (sprite-dimensions "ab
cdef
g")
      (with-soft-assertions
        (expect width :to-be 4)
        (expect height :to-be 3))))
  (it "reports 0 by 1 for empty text"
    (multiple-value-bind (width height) (sprite-dimensions "")
      (with-soft-assertions
        (expect width :to-be 0)
        (expect height :to-be 1))))
  (it "agrees with the sprite-width and sprite-height shorthands"
    (let ((art "ab
cdef"))
      (with-soft-assertions
        (expect (sprite-width art) :to-be 4)
        (expect (sprite-height art) :to-be 2)))))

(describe "sprite-row-span"
  (it "spans the whole line when it has no blank margin"
    (multiple-value-bind (start end) (sprite-row-span "abc")
      (with-soft-assertions
        (expect start :to-be 0)
        (expect end :to-be 3))))
  (it "excludes a leading blank margin, which is what stays transparent"
    (multiple-value-bind (start end) (sprite-row-span "  abc")
      (with-soft-assertions
        (expect start :to-be 2)
        (expect end :to-be 5))))
  (it "excludes a trailing blank margin"
    (multiple-value-bind (start end) (sprite-row-span "abc   ")
      (with-soft-assertions
        (expect start :to-be 0)
        (expect end :to-be 3))))
  (it "includes blanks enclosed between glyphs, so an interior gap stays opaque"
    (multiple-value-bind (start end) (sprite-row-span " a   b ")
      (with-soft-assertions
        (expect start :to-be 1)
        (expect end :to-be 6))))
  (it "reports an empty span for an all-blank line"
    (multiple-value-bind (start end) (sprite-row-span "     ")
      (with-soft-assertions
        (expect start :to-be 0)
        (expect end :to-be 0))))
  (it "reports an empty span for an empty line"
    (multiple-value-bind (start end) (sprite-row-span "")
      (with-soft-assertions
        (expect start :to-be 0)
        (expect end :to-be 0)))))
