;;;; src/conditions.lisp -- the package's condition hierarchy.
;;;;
;;;; Every condition this package signals derives from NYANCAT-ERROR, so a
;;;; caller can catch all of them with one HANDLER-CASE clause. Public
;;;; condition names carry the package prefix per CODING_STANDARD.md
;;;; "コンディションの設計".
(in-package #:cl-nyancat)

(define-condition nyancat-error (error) ()
  (:documentation "Base condition for every error this package signals."))

(defmacro define-nyancat-condition (name (&rest slots) report-control &key documentation)
  "Define NAME as a NYANCAT-ERROR subcondition, with one slot per (SLOT-NAME
READER) entry of SLOTS and a :REPORT that applies REPORT-CONTROL, a FORMAT
control string, to every slot's READER in SLOTS' own order. DOCUMENTATION, if
given, becomes NAME's :DOCUMENTATION.

Both this package's public conditions share that exact shape -- an
:INITARG/:READER pair per offending value, plus a report built only from
those readers -- so this macro is the declarative definition form for it,
per the nerima-lisp API standard's rule that a macro needs a reason beyond
what DEFINE-CONDITION alone already gives. Every argument is a name or a
literal string read at macro-expansion time, never a runtime value, so
nothing here needs gensym protection for evaluation order; CONDITION and
STREAM below are gensymed only so the expansion cannot capture a binding a
caller's own code happens to use.

    (define-nyancat-condition nyancat-invalid-band ((index nyancat-invalid-band-index))
      \"Rainbow band index ~S is outside the rainbow's band range.\"
      :documentation \"Signaled when a band index is out of range.\")

expands to a DEFINE-CONDITION of NYANCAT-INVALID-BAND under NYANCAT-ERROR
with one INDEX slot read by NYANCAT-INVALID-BAND-INDEX, a :REPORT lambda that
calls (NYANCAT-INVALID-BAND-INDEX CONDITION) as FORMAT's one argument, and
that :DOCUMENTATION string."
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
