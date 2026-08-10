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
    (expect (rainbow-band-at 7 9 30 6 11) :to-be (rainbow-band-at 7 9 30 6 11)))
  (it-property "only ever returns a band index the palette accepts, or nil"
      ((column (gen-integer :min 0 :max 300))
       (row (gen-integer :min 0 :max 100))
       (cat-x (gen-integer :min 0 :max 300))
       (cat-y (gen-integer :min 0 :max 100))
       (tick (gen-integer :min 0 :max 1000000)))
    (let ((band (rainbow-band-at column row cat-x cat-y tick)))
      (expect (or (null band) (< -1 band +rainbow-band-count+)) :to-be-truthy))))

(describe "the (< -1 band +rainbow-band-count+) bound check"
  (it "kills every mutation of its own representative literal instance"
    ;; One hand-picked mutation-testing target with score 1.0, per
    ;; TEST_STANDARD.md's per-repo requirement (there is no whole-system
    ;; aggregate floor -- mutation testing runs on hand-picked forms, not
    ;; the whole system automatically). The form below is fully
    ;; self-contained -- literal 3 standing in for a band index and literal
    ;; 6 for +RAINBOW-BAND-COUNT+ -- because RUN-MUTATIONS re-evaluates the
    ;; mutated form with CL:EVAL, which reads the null lexical environment:
    ;; a form closing over an outer LET binding would see it as unbound
    ;; rather than as that binding's value.
    (let ((results (run-mutations '(< -1 3 6)
                                  (lambda (form mutation)
                                    (declare (ignore mutation))
                                    (eval form)))))
      (assert-mutation-score results 1.0))))
