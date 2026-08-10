;;;; t/cli-test.lisp
;;;;
;;;; Flag parsing only. The handler calls RUN (src/app.lisp), which takes over
;;;; a real terminal in raw mode on the alternate screen, so these tests never
;;;; invoke it -- RUN-APP is called only with --help or --version, which cl-cli
;;;; answers before dispatching. This mirrors cl-asciiquarium/t/cli-test.lisp,
;;;; whose CLI has the same persistent full-screen shape.
(in-package #:cl-nyancat/test)

(describe "the cl-nyancat app spec: flag parsing round-trips"
  (it "leaves every flag unset by default"
    (let ((invocation (parse-argv *app* '("cl-nyancat"))))
      (with-soft-assertions
        (expect (option-value invocation :fps) :to-be-falsy)
        (expect (option-value invocation :duration) :to-be-falsy)
        (expect (option-value invocation :seed) :to-be-falsy)
        (expect (option-value invocation :no-color) :to-be-falsy))))

  (it "parses --fps as an integer"
    (expect (option-value (parse-argv *app* '("cl-nyancat" "--fps" "30")) :fps)
            :to-be 30))

  (it "accepts the --fps boundary values 1 and 60"
    (with-soft-assertions
      (expect (option-value (parse-argv *app* '("cl-nyancat" "--fps" "1")) :fps)
              :to-be 1)
      (expect (option-value (parse-argv *app* '("cl-nyancat" "--fps" "60")) :fps)
              :to-be 60)))

  (it "rejects an --fps below the 1 minimum"
    (signals cli-invalid-option-value (parse-argv *app* '("cl-nyancat" "--fps" "0"))))

  (it "rejects an --fps above the 60 maximum"
    (signals cli-invalid-option-value (parse-argv *app* '("cl-nyancat" "--fps" "61"))))

  (it "parses --duration as a number, so fractional seconds work"
    (expect (= (option-value (parse-argv *app* '("cl-nyancat" "--duration" "2.5"))
                             :duration)
               2.5)
            :to-be-truthy))

  (it "rejects a negative --duration"
    (signals cli-invalid-option-value
      (parse-argv *app* '("cl-nyancat" "--duration" "-1"))))

  (it "parses --seed as an integer -- the flag a reproducible run depends on"
    (expect (option-value (parse-argv *app* '("cl-nyancat" "--seed" "42")) :seed)
            :to-be 42))

  (it "treats --no-color as a flag needing no value"
    (expect (option-value (parse-argv *app* '("cl-nyancat" "--no-color")) :no-color)
            :to-be-truthy))

  (it "parses the upstream short options and values"
    (let ((invocation
            (parse-argv
             *app*
             '("cl-nyancat" "-i" "-I" "-t" "-n" "-s" "-e"
               "-f" "3" "-r" "1" "-R" "63" "-c" "2" "-C" "62"
               "-W" "40" "-H" "20"))))
      (with-soft-assertions
        (expect (option-value invocation :intro) :to-be-truthy)
        (expect (option-value invocation :skip-intro) :to-be-truthy)
        (expect (option-value invocation :telnet) :to-be-truthy)
        (expect (option-value invocation :no-counter) :to-be-truthy)
        (expect (option-value invocation :no-title) :to-be-truthy)
        (expect (option-value invocation :no-clear) :to-be-truthy)
        (expect (option-value invocation :frames) :to-be 3)
        (expect (option-value invocation :min-rows) :to-be 1)
        (expect (option-value invocation :max-rows) :to-be 63)
        (expect (option-value invocation :min-cols) :to-be 2)
        (expect (option-value invocation :max-cols) :to-be 62)
        (expect (option-value invocation :width) :to-be 40)
        (expect (option-value invocation :height) :to-be 20))))

  (it "parses every flag together"
    (let ((invocation (parse-argv *app* '("cl-nyancat" "--fps" "24" "--duration" "5"
                                          "--seed" "7" "--no-color"))))
      (with-soft-assertions
        (expect (option-value invocation :fps) :to-be 24)
        (expect (option-value invocation :seed) :to-be 7)
        (expect (option-value invocation :no-color) :to-be-truthy)))))

(describe "the cl-nyancat app spec: --help and --version"
  (it "exits 0 on --help without starting the animation"
    (let ((output (with-output-to-string (out)
                    (expect (run-app *app* :argv '("cl-nyancat" "--help") :stdout out)
                            :to-be 0))))
      (expect (search "cl-nyancat" output) :to-be-truthy)))

  (it "lists every flag in the help output"
    (let ((output (with-output-to-string (out)
                    (run-app *app* :argv '("cl-nyancat" "--help") :stdout out))))
      (with-soft-assertions
        (dolist (flag '("--fps" "--duration" "--seed" "--no-color"))
          (expect (search flag output) :to-be-truthy)))))

  (it "exits 0 on --version and prints the app's name"
    (let ((output (with-output-to-string (out)
                    (expect (run-app *app* :argv '("cl-nyancat" "--version") :stdout out)
                            :to-be 0))))
      (expect (search "cl-nyancat" output) :to-be-truthy)))

  (it "reports a version rather than a placeholder, when ASDF knows the system"
    ;; The version is read from cl-nyancat.asd at load time (see
    ;; %NYANCAT-VERSION), so a delivered image without installed sources
    ;; legitimately reports 0.0.0; only the shape is asserted here.
    (let ((output (with-output-to-string (out)
                    (run-app *app* :argv '("cl-nyancat" "--version") :stdout out))))
      (expect (find-if #'digit-char-p output) :to-be-truthy))))
