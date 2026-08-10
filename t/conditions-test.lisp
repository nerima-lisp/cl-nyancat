;;;; t/conditions-test.lisp -- condition hierarchy and generated reports.
(in-package #:cl-nyancat/test)

(describe "condition hierarchy"
  (it "reports invalid dimensions through the generated condition definition"
    (let ((caught nil))
      (handler-case
          (make-world :width 0 :height -2)
        (nyancat-invalid-dimensions (condition)
          (setf caught t)
          (with-soft-assertions
            (expect (typep condition 'nyancat-error) :to-be-truthy)
            (expect (typep condition 'error) :to-be-truthy)
            (expect (nyancat-invalid-dimensions-width condition) :to-be 0)
            (expect (nyancat-invalid-dimensions-height condition) :to-be -2)
            (expect (format nil "~A" condition)
                    :to-equal
                    "Invalid world dimensions 0x-2: both must be positive integers."))))
      (expect caught :to-be-truthy)))
  (it "reports invalid rainbow bands through the same macro shape"
    (let ((caught nil))
      (handler-case
          (rainbow-band-char 6 nil)
        (nyancat-invalid-band (condition)
          (setf caught t)
          (with-soft-assertions
            (expect (typep condition 'nyancat-error) :to-be-truthy)
            (expect (nyancat-invalid-band-index condition) :to-be 6)
            (expect (format nil "~A" condition)
                    :to-equal
                    "Rainbow band index 6 is outside the rainbow's band range."))))
      (expect caught :to-be-truthy))))
