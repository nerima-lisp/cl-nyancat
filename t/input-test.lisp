;;;; t/input-test.lisp
;;;;
;;;; KEY-EVENTs are built by handing cl-tty-kit's own DECODE-INPUT a plain
;;;; string, rather than by constructing event structs here: that exercises the
;;;; same decoder the running application uses, so a change in how cl-tty-kit
;;;; reports a key is caught here instead of only in a real terminal.
;;;;
;;;; Control characters are written as (code-char N) and compared by CHAR-CODE.
;;;; A literal control character in this file would be echoed by any tool that
;;;; prints a failing assertion's input, which has hung an interactive terminal
;;;; in this org before.
(in-package #:cl-nyancat/test)

(defparameter +control-c-string+ (string (code-char 3))
  "The single byte Ctrl-C sends. Raw mode clears ISIG, so it arrives as input
rather than as SIGINT -- see +QUIT-CHARACTERS+ in src/input.lisp.")

(defun events-for (string)
  "Return the cl-tty-kit KEY-EVENTs STRING decodes to."
  (decode-input string))

(describe "quit-key-event-p"
  (it "accepts a lowercase q"
    (expect (every #'quit-key-event-p (events-for "q")) :to-be-truthy))
  (it "accepts an uppercase Q"
    (expect (every #'quit-key-event-p (events-for "Q")) :to-be-truthy))
  (it "accepts Ctrl-C, which raw mode delivers as input rather than a signal"
    (expect (some #'quit-key-event-p (events-for +control-c-string+)) :to-be-truthy))
  (it "rejects an unrelated printable key"
    (expect (some #'quit-key-event-p (events-for "z")) :to-be-falsy))
  (it "rejects the color-toggle key"
    (expect (some #'quit-key-event-p (events-for "c")) :to-be-falsy)))

(describe "world-apply-key-event"
  (it "sets the quit flag on q"
    (let ((world (make-world)))
      (world-apply-key-events world (events-for "q"))
      (expect (world-quitp world) :to-be-truthy)))
  (it "sets the quit flag on Ctrl-C"
    (let ((world (make-world)))
      (world-apply-key-events world (events-for +control-c-string+))
      (expect (world-quitp world) :to-be-truthy)))
  (it "makes the world finished, which is what stops the tick loop"
    (let ((world (make-world)))
      (world-apply-key-events world (events-for "Q"))
      (expect (world-finished-p world) :to-be-truthy)))
  (it "toggles color off on c"
    (let ((world (make-world :colorp t)))
      (world-apply-key-events world (events-for "c"))
      (expect (world-colorp world) :to-be-falsy)))
  (it "toggles color back on with a second c"
    (let ((world (make-world :colorp t)))
      (world-apply-key-events world (events-for "cc"))
      (expect (world-colorp world) :to-be-truthy)))
  (it "leaves the world alone for an unbound key"
    (let ((world (make-world :colorp t)))
      (world-apply-key-events world (events-for "xyz"))
      (with-soft-assertions
        (expect (world-quitp world) :to-be-falsy)
        (expect (world-colorp world) :to-be-truthy))))
  (it "ignores an unbound special key such as an arrow"
    (let ((world (make-world)))
      ;; CSI A -- the up arrow. Built from (code-char 27) rather than a literal
      ;; escape byte, for the reason given in this file's header.
      (world-apply-key-events world (events-for (format nil "~C[A" (code-char 27))))
      (expect (world-quitp world) :to-be-falsy)))
  (it "returns the world it was given"
    (let ((world (make-world)))
      (expect (world-apply-key-events world (events-for "q")) :to-be world)))
  (it "accepts an empty event list, which is what a tick with no input yields"
    (let ((world (make-world)))
      (world-apply-key-events world nil)
      (expect (world-quitp world) :to-be-falsy)))
  (it "applies every event in a burst, so quitting is not lost behind other keys"
    (let ((world (make-world)))
      (world-apply-key-events world (events-for "xyq"))
      (expect (world-quitp world) :to-be-truthy))))
