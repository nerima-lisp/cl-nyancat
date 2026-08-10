(in-package #:cl-nyancat/test)

(describe "duration-to-ticks"
  (it "returns NIL only when no duration or frame limit was requested" (with-soft-assertions (expect (cl-nyancat::%duration-to-ticks nil 12) :to-be-falsy) (expect (cl-nyancat::%duration-to-ticks nil 12 1) :to-be 1) (expect (cl-nyancat::%duration-to-ticks nil 12 5) :to-be 5) (expect (cl-nyancat::%duration-to-ticks 1 12 20) :to-be 12) (expect (cl-nyancat::%duration-to-ticks 1 12 5) :to-be 5)))
  (it "keeps a sub-frame duration visible for one tick"
    (expect (cl-nyancat::%duration-to-ticks 0.01 12) :to-be 1))
  (it "rounds a duration up to the next whole frame"
    (expect (cl-nyancat::%duration-to-ticks 1.01 12) :to-be 13))
  (it-property "returns at least one tick for every positive duration"
      ((milliseconds (gen-integer :min 1 :max 10000))
       (fps (gen-integer :min 1 :max 120)))
    (expect (>= (cl-nyancat::%duration-to-ticks (/ milliseconds 1000.0) fps)
                1)
            :to-be-truthy)))

(describe "duration-to-ticks validation"
  (it "keeps an explicit zero duration visible for one tick"
    (expect (cl-nyancat::%duration-to-ticks 0 12) :to-be 1))
  (it "rejects a non-positive frame rate"
    (signals type-error
      (cl-nyancat::%duration-to-ticks nil 0)))
  (it "rejects a non-integer frame rate"
    (signals type-error
      (cl-nyancat::%duration-to-ticks nil 12.5)))
  (it "rejects a negative duration and a non-positive frame count" (signals type-error (cl-nyancat::%duration-to-ticks -0.01 12)) (signals type-error (cl-nyancat::%duration-to-ticks nil 12 0))))
