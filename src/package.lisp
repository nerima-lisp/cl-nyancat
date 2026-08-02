;;;; src/package.lisp -- the sole DEFPACKAGE form for this repository.
;;;;
;;;; CODING_STANDARD.md requires `:use` to name only #:cl and every sibling
;;;; package to come in through `:import-from`, so the long import lists below
;;;; are the price of that rule, not an oversight.
(in-package #:cl-user)

(defpackage #:cl-nyancat
  (:use #:cl)
  ;; cl-tty-kit (L1): screens, sprite compositing, cell styles, the tick loop,
  ;; raw mode, and input decoding -- the whole rendering/IO substrate. See
  ;; docs/src/reference/architecture.md for how the pieces below compose.
  (:import-from #:cl-tty-kit
                #:make-screen
                #:screen-width
                #:screen-height
                #:screen-clear
                #:screen-put-cell
                #:screen-to-string
                #:sprite-blit
                #:make-style
                #:style-fg
                #:make-renderer
                #:renderer-screen
                #:renderer-render
                #:renderer-resize
                #:tick-loop-run-realtime
                #:with-raw-mode
                #:with-terminal-session
                #:terminal-size
                #:make-input-decoder
                #:decode-input-chunk
                #:key-event-type
                #:key-event-code)
  ;; cl-cli (L1): the --fps/--duration/--seed/--no-color command-line surface.
  (:import-from #:cl-cli
                #:make-app
                #:make-option
                #:run-app
                #:option-value
                #:current-process-argv)
  (:export
   ;; -- Conditions --
   #:nyancat-error
   #:nyancat-invalid-dimensions
   #:nyancat-invalid-dimensions-width
   #:nyancat-invalid-dimensions-height
   #:nyancat-invalid-band
   #:nyancat-invalid-band-index

   ;; -- Sprite geometry helpers --
   #:split-sprite-lines
   #:sprite-dimensions
   #:sprite-width
   #:sprite-height
   #:sprite-row-span
   #:clamp

   ;; -- Palette: the colors and glyphs every layer draws with --
   #:+rainbow-band-count+
   #:rainbow-band-style
   #:rainbow-band-char
   #:star-style
   #:cat-style

   ;; -- The cat sprite --
   #:+cat-frame-count+
   #:cat-frame
   #:cat-frame-for-tick
   #:cat-frame-part
   #:cat-art-width
   #:cat-art-height

   ;; -- Starfield: a pure function of (seed, column, row, tick) --
   #:star-hash
   #:star-present-p
   #:star-char-at

   ;; -- Rainbow trail --
   #:+rainbow-wave-amplitude+
   #:rainbow-wave-offset
   #:rainbow-band-at

   ;; -- World state --
   #:world
   #:world-p
   #:make-world
   #:world-width
   #:world-height
   #:world-tick
   #:world-seed
   #:world-colorp
   #:world-quitp
   #:world-max-ticks
   #:world-cat-x
   #:world-cat-y
   #:world-resize

   ;; -- Simulation step --
   #:world-advance
   #:world-finished-p
   #:world-cat-frame

   ;; -- Input --
   #:quit-key-event-p
   #:world-apply-key-event
   #:world-apply-key-events

   ;; -- Rendering --
   #:draw-stars
   #:draw-rainbow
   #:draw-cat
   #:draw-world
   #:world-to-string
   #:render-frame

   ;; -- Application entry points --
   #:run
   #:*app*
   #:main
   #:image-entry-point))
