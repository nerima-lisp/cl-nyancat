;;;; t/app-test.lisp -- the input side of the real terminal boundary.
;;;;
;;;; The stream is real and cl-tty-kit's public poller is used directly. Only
;;;; the source of bytes is deterministic, so this test does not fake a
;;;; terminal session or duplicate the decoder in the application.
(in-package #:cl-nyancat/test)

(describe "world poller"
  (it "passes stream input through cl-tty-kit's public poller"
    (let ((world (make-world :width 80 :height 24))
          (renderer (make-renderer 80 24)))
      (let ((*standard-input* (make-string-input-stream "q")))
        (funcall (cl-nyancat::%make-world-poller renderer) world))
      (with-soft-assertions
        (expect (world-quitp world) :to-be-truthy)
        (expect (world-finished-p world) :to-be-truthy)))))
