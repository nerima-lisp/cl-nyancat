(in-package #:cl-nyancat/test)

(describe "make-world"
  (it "records the size it was given"
    (let ((world (make-world :width 100 :height 30)))
      (with-soft-assertions
        (expect (world-width world) :to-be 100)
        (expect (world-height world) :to-be 30))))
  (it "starts at tick zero, not quitting, in color, with no duration limit"
    (let ((world (make-world)))
      (with-soft-assertions
        (expect (world-tick world) :to-be 0)
        (expect (world-quitp world) :to-be-falsy)
        (expect (world-colorp world) :to-be-truthy)
        (expect (world-max-ticks world) :to-be-falsy))))
  (it "honours an explicit seed, colorp and max-ticks"
    (let ((world (make-world :seed 99 :colorp nil :max-ticks 250)))
      (with-soft-assertions
        (expect (world-seed world) :to-be 99)
        (expect (world-colorp world) :to-be-falsy)
        (expect (world-max-ticks world) :to-be 250))))
  (it "keeps the whole cat on screen when the terminal is big enough"
    (let ((world (make-world :width 120 :height 40)))
      (with-soft-assertions
        (expect (<= 0 (world-cat-x world)) :to-be-truthy)
        (expect (<= (+ (world-cat-x world) (cat-art-width)) 120) :to-be-truthy)
        (expect (<= (+ (world-cat-y world) (cat-art-height)) 40) :to-be-truthy))))
  (it "puts the cat right of center, leaving the rainbow the longer side"
    (let ((world (make-world :width 200 :height 40)))
      (expect (> (world-cat-x world) 100) :to-be-truthy)))
  (it "pins the cat to the corner rather than off screen on a tiny terminal"
    (let ((world (make-world :width 3 :height 2)))
      (with-soft-assertions
        (expect (world-cat-x world) :to-be 0)
        (expect (world-cat-y world) :to-be 0))))
  (it "leaves room left of the cat for a rainbow at a normal terminal width"
    (expect (plusp (world-cat-x (make-world :width 80 :height 24))) :to-be-truthy))
  (it-each ((0 10) (10 -1) (10.5 10))
      "rejects width ~A, height ~A"
      (width height)
    (signals nyancat-invalid-dimensions (make-world :width width :height height)))
  (it "reports both offending dimensions on the signalled condition"
    (handler-case (make-world :width 0 :height -2)
      (nyancat-invalid-dimensions (condition)
        (with-soft-assertions
          (expect (nyancat-invalid-dimensions-width condition) :to-be 0)
          (expect (nyancat-invalid-dimensions-height condition) :to-be -2))))))

(describe "world-resize"
  (it "adopts the new size"
    (let ((world (make-world :width 80 :height 24)))
      (world-resize world 40 12)
      (with-soft-assertions
        (expect (world-width world) :to-be 40)
        (expect (world-height world) :to-be 12))))
  (it "re-places the cat for the new size"
    (let ((world (make-world :width 200 :height 40)))
      (let ((before (world-cat-x world)))
        (world-resize world 60 20)
        (expect (= before (world-cat-x world)) :to-be-falsy))))
  (it "keeps the cat on screen after shrinking"
    (let ((world (make-world :width 200 :height 40)))
      (world-resize world 30 10)
      (with-soft-assertions
        (expect (< (world-cat-x world) 30) :to-be-truthy)
        (expect (< (world-cat-y world) 10) :to-be-truthy))))
  (it "does not reset the tick, since the layers are functions of it"
    (let ((world (make-world :width 80 :height 24)))
      (dotimes (i 7) (world-advance world))
      (world-resize world 100 30)
      (expect (world-tick world) :to-be 7)))
  (it "returns the same world object it was given"
    (let ((world (make-world)))
      (expect (world-resize world 50 20) :to-be world)))
  (it "rejects invalid dimensions"
    (signals nyancat-invalid-dimensions (world-resize (make-world) 0 5))))
