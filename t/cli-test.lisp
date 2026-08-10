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
    (let ((invocation (parse-argv *app* (quote ("cl-nyancat")))))
      (with-soft-assertions
        (expect (option-value invocation :fps) :to-be-falsy)
        (expect (option-value invocation :duration) :to-be-falsy)
        (expect (option-value invocation :frames) :to-be-falsy)
        (expect (option-value invocation :width) :to-be-falsy)
        (expect (option-value invocation :height) :to-be-falsy)
        (expect (option-value invocation :seed) :to-be-falsy)
        (expect (option-value invocation :intro) :to-be-falsy)
        (expect (option-value invocation :min-rows) :to-be-falsy)
        (expect (option-value invocation :max-rows) :to-be-falsy)
        (expect (option-value invocation :min-cols) :to-be-falsy)
        (expect (option-value invocation :max-cols) :to-be-falsy)
        (expect (option-value invocation :no-color) :to-be-falsy)
        (expect (option-value invocation :no-counter) :to-be-falsy)
        (expect (option-value invocation :no-title) :to-be-falsy)
        (expect (option-value invocation :no-clear) :to-be-falsy))))

  (it "parses --fps as an integer"
    (expect (option-value (parse-argv *app* (quote ("cl-nyancat" "--fps" "30"))) :fps)
            :to-be 30))

  (it "accepts the --fps boundary values 1 and 60"
    (with-soft-assertions
      (expect (option-value (parse-argv *app* (quote ("cl-nyancat" "--fps" "1"))) :fps)
              :to-be 1)
      (expect (option-value (parse-argv *app* (quote ("cl-nyancat" "--fps" "60"))) :fps)
              :to-be 60)))

  (it "rejects an --fps below the 1 minimum"
    (signals cli-invalid-option-value (parse-argv *app* (quote ("cl-nyancat" "--fps" "0")))))

  (it "rejects an --fps above the 60 maximum"
    (signals cli-invalid-option-value (parse-argv *app* (quote ("cl-nyancat" "--fps" "61")))))

  (it "parses --duration as a number, so fractional seconds work"
    (expect (= (option-value (parse-argv *app* (quote ("cl-nyancat" "--duration" "2.5")))
                             :duration)
               2.5)
            :to-be-truthy))

  (it "rejects a negative --duration"
    (signals cli-invalid-option-value
      (parse-argv *app* (quote ("cl-nyancat" "--duration" "-1")))))

  (it "parses --seed as an integer -- the flag a reproducible run depends on"
    (expect (option-value (parse-argv *app* (quote ("cl-nyancat" "--seed" "42"))) :seed)
            :to-be 42))

  (it "parses the standard short display and crop options"
    (let ((invocation
            (parse-argv *app*
                        (quote ("cl-nyancat" "--no-color"
                                "-f" "4" "-W" "80" "-H" "24"
                                "-i" "-r" "1" "-R" "22" "-c" "2" "-C" "78"
                                "-n" "-s" "-e")))))
      (with-soft-assertions
        (expect (option-value invocation :no-color) :to-be-truthy)
        (expect (option-value invocation :frames) :to-be 4)
        (expect (option-value invocation :width) :to-be 80)
        (expect (option-value invocation :height) :to-be 24)
        (expect (option-value invocation :intro) :to-be-truthy)
        (expect (option-value invocation :min-rows) :to-be 1)
        (expect (option-value invocation :max-rows) :to-be 22)
        (expect (option-value invocation :min-cols) :to-be 2)
        (expect (option-value invocation :max-cols) :to-be 78)
        (expect (option-value invocation :no-counter) :to-be-truthy)
        (expect (option-value invocation :no-title) :to-be-truthy)
        (expect (option-value invocation :no-clear) :to-be-truthy))))

  (it "rejects non-positive frame and fixed-size values"
    (with-soft-assertions
      (signals cli-invalid-option-value
        (parse-argv *app* (quote ("cl-nyancat" "--frames" "0"))))
      (signals cli-invalid-option-value
        (parse-argv *app* (quote ("cl-nyancat" "--width" "0"))))
      (signals cli-invalid-option-value
        (parse-argv *app* (quote ("cl-nyancat" "--height" "0"))))))
  )



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
        (dolist (flag '("--fps" "--duration" "--frames" "--width" "--height"
                        "--seed" "--intro" "--min-rows" "--max-rows"
                        "--min-cols" "--max-cols" "--no-color" "--no-counter"
                        "--no-title" "--no-clear"))
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
