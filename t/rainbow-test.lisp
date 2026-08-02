(in-package #:cl-nyancat/test)

(describe "rainbow-wave-offset"
  (it "returns only the two step heights the wave has"
    (with-soft-assertions
      (loop for column below 64
            do (expect (member (rainbow-wave-offset column 0)
                               (list 0 +rainbow-wave-amplitude+))
                       :to-be-truthy))))
  (it "holds a step for several columns before switching, so it reads as a ripple"
    (expect (rainbow-wave-offset 0 0) :to-be (rainbow-wave-offset 1 0)))
  (it "does switch: the wave is not a flat line"
    (expect (find-if (lambda (column)
                       (/= (rainbow-wave-offset column 0) (rainbow-wave-offset 0 0)))
                     (loop for column below 32 collect column))
            :to-be-truthy))
  (it "travels at exactly the starfield's speed, one column per tick"
    ;; The rainbow and the stars must not drift apart; both read the world
    ;; column as (screen column + tick).
    (with-soft-assertions
      (loop for column from 1 below 40
            do (expect (rainbow-wave-offset column 0)
                       :to-be (rainbow-wave-offset (1- column) 1))))))

(describe "rainbow-band-at"
  (it "covers nothing at or right of the cat, which is where the cat is drawn"
    (with-soft-assertions
      (loop for column from 20 below 30
            do (expect (rainbow-band-at column 5 20 5 0) :to-be-falsy))))
  (it "covers the full band stack directly left of the cat"
    (let ((bands (loop for row from 5 below (+ 5 +rainbow-band-count+)
                       collect (rainbow-band-at 19 row 20 5 0))))
      ;; Column 19 at tick 0 sits on one of the two wave steps; whichever it
      ;; is, the stack is contiguous and complete somewhere in the sampled
      ;; rows, so only the count of covered rows is asserted here.
      (expect (count-if #'identity bands)
              :to-be (- +rainbow-band-count+
                        (rainbow-wave-offset 19 0)))))
  (it "numbers bands from 0 downwards from the trail's top edge"
    (let* ((column 0)
           (top (+ 5 (rainbow-wave-offset column 0))))
      (with-soft-assertions
        (expect (rainbow-band-at column top 20 5 0) :to-be 0)
        (expect (rainbow-band-at column (1+ top) 20 5 0) :to-be 1))))
  (it "covers nothing above the trail's top edge"
    (let* ((column 0)
           (top (+ 5 (rainbow-wave-offset column 0))))
      (expect (rainbow-band-at column (1- top) 20 5 0) :to-be-falsy)))
  (it "covers nothing below the last band"
    (let* ((column 0)
           (top (+ 5 (rainbow-wave-offset column 0))))
      (expect (rainbow-band-at column (+ top +rainbow-band-count+) 20 5 0)
              :to-be-falsy)))
  (it "only ever returns a band index the palette accepts"
    (with-soft-assertions
      (loop for column below 40
            do (loop for row below 24
                     for band = (rainbow-band-at column row 40 8 3)
                     when band
                       do (expect (< -1 band +rainbow-band-count+) :to-be-truthy)))))
  (it "leaves every band visible somewhere across the trail's width"
    (let ((seen (remove-duplicates
                 (loop for column below 40
                       append (loop for row below 24
                                    for band = (rainbow-band-at column row 40 8 0)
                                    when band collect band)))))
      (expect (length seen) :to-be +rainbow-band-count+)))
  (it "is a pure function of its arguments"
    (expect (rainbow-band-at 7 9 30 6 11) :to-be (rainbow-band-at 7 9 30 6 11))))
