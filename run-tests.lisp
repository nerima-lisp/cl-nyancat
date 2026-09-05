;;;; run-tests.lisp
;;;;
;;;; Run with: sbcl --script run-tests.lisp
;;;; The caller supplies CL_SOURCE_REGISTRY for sibling dependencies.

(require :asdf)

(defun script-directory ()
  (make-pathname :name nil
                 :type nil
                 :defaults (or *load-truename*
                               *compile-file-truename*
                               (error "Unable to determine the script location"))))

(defun configure-local-source-registry (root)
  (asdf:initialize-source-registry
   `(:source-registry
     (:tree ,root)
     :inherit-configuration)))

(let ((root (script-directory)))
  (configure-local-source-registry root)
  (asdf:test-system "cl-nyancat")
  (uiop:quit 0))
