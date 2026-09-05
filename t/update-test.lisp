(in-package #:cl-nyancat/test)

(describe "world-advance"
  (it "advances the tick by exactly one"
    (let ((world (make-world)))
      (world-advance world)
      (expect (world-tick world) :to-be 1)))
  (it "returns the same world object, matching the tick loop's in-place contract"
    (let ((world (make-world)))
      (expect (world-advance world) :to-be world)))
  (it "changes nothing else about the world"
    (let ((world (make-world :width 80 :height 24 :seed 5)))
      (let ((cat-x (world-cat-x world))
            (cat-y (world-cat-y world)))
        (world-advance world)
        (with-soft-assertions
          (expect (world-cat-x world) :to-be cat-x)
          (expect (world-cat-y world) :to-be cat-y)
          (expect (world-seed world) :to-be 5)
          (expect (world-quitp world) :to-be-falsy)))))
  (it "reaches tick N after N calls, with no drift"
    (let ((world (make-world)))
      (dotimes (i 1000) (world-advance world))
      (expect (world-tick world) :to-be 1000))))

(describe "world-finished-p"
  (it "is false for a fresh world with no duration limit"
    (expect (world-finished-p (make-world)) :to-be-falsy))
  (it "is true once the quit flag is set"
    (let ((world (make-world)))
      (setf (world-quitp world) t)
      (expect (world-finished-p world) :to-be-truthy)))
  (it "stays false forever without a max-tick, however long the run"
    (let ((world (make-world)))
      (dotimes (i 5000) (world-advance world))
      (expect (world-finished-p world) :to-be-falsy)))
  (it "is false before the max tick is reached"
    (let ((world (make-world :max-ticks 10)))
      (dotimes (i 9) (world-advance world))
      (expect (world-finished-p world) :to-be-falsy)))
  (it "is true exactly at the max tick, so --duration is not off by one"
    (let ((world (make-world :max-ticks 10)))
      (dotimes (i 10) (world-advance world))
      (expect (world-finished-p world) :to-be-truthy)))
  (it "stays true past the max tick"
    (let ((world (make-world :max-ticks 3)))
      (dotimes (i 20) (world-advance world))
      (expect (world-finished-p world) :to-be-truthy)))
  (it "is true immediately for a max-ticks of zero"
    (expect (world-finished-p (make-world :max-ticks 0)) :to-be-truthy)))

(describe "world-cat-frame"
  (it "returns sprite text for the current tick"
    (expect (stringp (world-cat-frame (make-world))) :to-be-truthy))
  (it "matches what cat-frame-for-tick selects"
    (let ((world (make-world)))
      (dotimes (i 5) (world-advance world))
      (expect (world-cat-frame world)
              :to-equal (cat-frame (cat-frame-for-tick (world-tick world))))))
  (it "eventually shows a different frame as the world advances"
    (let* ((world (make-world))
           (first-frame (world-cat-frame world)))
      (expect (loop repeat 64
                    do (world-advance world)
                    thereis (not (string= first-frame (world-cat-frame world))))
              :to-be-truthy))))

(describe "the whole pipeline's determinism"
  (it "renders two same-seed worlds identically at the same tick"
    ;; A pure hash makes replay independent of mutable generator state.
    (let ((left (make-world :width 60 :height 20 :seed 1234))
          (right (make-world :width 60 :height 20 :seed 1234)))
      (dotimes (i 37)
        (world-advance left)
        (world-advance right))
      (expect (world-to-string left) :to-equal (world-to-string right))))
  (it "renders different seeds differently"
    (let ((left (make-world :width 60 :height 20 :seed 1))
          (right (make-world :width 60 :height 20 :seed 2)))
      (expect (equal (world-to-string left) (world-to-string right)) :to-be-falsy)))
  (it "renders a jumped-to tick the same as one reached by advancing"
    ;; Setting the tick must match advancing to it.
    (let ((advanced (make-world :width 60 :height 20 :seed 7))
          (jumped (make-world :width 60 :height 20 :seed 7)))
      (dotimes (i 500) (world-advance advanced))
      (setf (world-tick jumped) 500)
      (expect (world-to-string advanced) :to-equal (world-to-string jumped)))))
