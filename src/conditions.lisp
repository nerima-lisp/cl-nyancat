;;;; src/conditions.lisp -- the package's condition hierarchy.
;;;;
;;;; Every condition this package signals derives from NYANCAT-ERROR, so a
;;;; caller can catch all of them with one HANDLER-CASE clause. Public
;;;; condition names carry the package prefix per CODING_STANDARD.md
;;;; "コンディションの設計".
(in-package #:cl-nyancat)

(define-condition nyancat-error (error) ()
  (:documentation "Base condition for every error this package signals."))

(define-condition nyancat-invalid-dimensions (nyancat-error)
  ((width :initarg :width :reader nyancat-invalid-dimensions-width)
   (height :initarg :height :reader nyancat-invalid-dimensions-height))
  (:report (lambda (condition stream)
             (format stream "Invalid world dimensions ~Dx~D: both must be positive integers."
                     (nyancat-invalid-dimensions-width condition)
                     (nyancat-invalid-dimensions-height condition))))
  (:documentation "Signaled when MAKE-WORLD or WORLD-RESIZE is given a
non-positive width or height."))

(define-condition nyancat-invalid-band (nyancat-error)
  ((index :initarg :index :reader nyancat-invalid-band-index))
  ;; The upper bound is spelled by the caller rather than read from
  ;; +RAINBOW-BAND-COUNT+: palette.lisp defines that constant and is loaded
  ;; after this file, so naming it here would be an undefined-variable warning
  ;; at compile time for a value only ever read at report time.
  (:report (lambda (condition stream)
             (format stream "Rainbow band index ~S is outside the rainbow's band range."
                     (nyancat-invalid-band-index condition))))
  (:documentation "Signaled when RAINBOW-BAND-STYLE or RAINBOW-BAND-CHAR is
asked for a band outside [0, +RAINBOW-BAND-COUNT+)."))
