;;;; src/input.lisp -- turning decoded cl-tty-kit KEY-EVENTs into WORLD changes.
(in-package #:cl-nyancat)

(defparameter +quit-characters+ (list #\q #\Q)
  "Characters that set WORLD-QUITP on a decoded :CHARACTER event, by
application convention (q/Q). Ctrl-C is matched separately, on the decoded
event's type rather than on a character: raw mode clears ISIG (see
cl-tty-kit's raw-mode-sbcl.lisp), so Ctrl-C never reaches this process as
SIGINT and cl-tty-kit's decoder reports it as a :SPECIAL event with code
:CONTROL-C -- see +CONTROL-LETTER-EVENTS+ in cl-tty-kit's key-tables.lisp --
rather than as a raw byte this file would have to inspect itself.")

(defun quit-key-event-p (event)
  "True when the decoded cl-tty-kit KEY-EVENT should stop the animation.
That is a :CHARACTER event whose code is in +QUIT-CHARACTERS+, or the :SPECIAL
:CONTROL-C event Ctrl-C decodes to under raw mode."
  (or (and (eq (key-event-type event) :character)
           (member (key-event-code event) +quit-characters+ :test #'char=))
      (and (eq (key-event-type event) :special)
           (eq (key-event-code event) :control-c))))

(defun world-apply-key-event (world event)
  "Apply one decoded cl-tty-kit KEY-EVENT to WORLD, returning WORLD.
An event satisfying QUIT-KEY-EVENT-P sets WORLD-QUITP; a :CHARACTER event with
code #\\c or #\\C toggles WORLD-COLORP, which is the same switch --no-color
sets and is useful for checking a terminal's color support without restarting.
Every other event, including the :SPECIAL keys this application does not bind,
is ignored."
  (cond
    ((quit-key-event-p event)
     (setf (world-quitp world) t))
    ((and (eq (key-event-type event) :character)
          (member (key-event-code event) '(#\c #\C) :test #'char=))
     (setf (world-colorp world) (not (world-colorp world)))))
  world)

(defun world-apply-key-events (world events)
  "Apply each of EVENTS to WORLD in order via WORLD-APPLY-KEY-EVENT, returning WORLD."
  (dolist (event events world)
    (world-apply-key-event world event)))
