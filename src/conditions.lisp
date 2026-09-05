;;;; src/conditions.lisp -- the package's condition hierarchy.
;;;;
;;;; Every condition this package signals derives from NYANCAT-ERROR, so a
;;;; caller can catch all of them with one HANDLER-CASE clause.
(in-package #:cl-nyancat)

(define-condition nyancat-error (error) ()
  (:documentation "Base condition for every error this package signals."))

(defmacro define-nyancat-condition (name (&rest slots) report-control &key documentation)
  "Define NAME as a NYANCAT-ERROR subcondition.

SLOTS supplies (SLOT-NAME READER) pairs; REPORT-CONTROL reports the values
returned by those readers. DOCUMENTATION, when supplied, becomes the
condition's documentation."
  (let ((condition (gensym "CONDITION"))
        (stream (gensym "STREAM")))
    `(define-condition ,name (nyancat-error)
       ,(mapcar (lambda (slot)
                  (destructuring-bind (slot-name reader) slot
                    (list slot-name :initarg (intern (symbol-name slot-name) :keyword)
                          :reader reader)))
                slots)
       (:report (lambda (,condition ,stream)
                  (format ,stream ,report-control
                          ,@(mapcar (lambda (slot) (list (second slot) condition)) slots))))
       ,@(when documentation `((:documentation ,documentation))))))

(define-nyancat-condition nyancat-invalid-dimensions
    ((width nyancat-invalid-dimensions-width) (height nyancat-invalid-dimensions-height))
  "Invalid world dimensions ~Dx~D: both must be positive integers."
  :documentation "Signaled when MAKE-WORLD or WORLD-RESIZE is given a
non-positive width or height.")

;; The upper bound is spelled by the caller rather than read from
;; +RAINBOW-BAND-COUNT+: palette.lisp defines that constant and is loaded
;; after this file, so naming it here would be an undefined-variable warning
;; at compile time for a value only ever read at report time.
(define-nyancat-condition nyancat-invalid-band ((index nyancat-invalid-band-index))
  "Rainbow band index ~S is outside the rainbow's band range."
  :documentation "Signaled when RAINBOW-BAND-STYLE or RAINBOW-BAND-CHAR is
asked for a band outside [0, +RAINBOW-BAND-COUNT+).")
