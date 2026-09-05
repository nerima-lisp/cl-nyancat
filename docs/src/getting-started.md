# Getting started

## Requirements

SBCL. Its direct dependencies are
[cl-tty-kit](https://github.com/nerima-lisp/cl-tty-kit) and
[cl-cli](https://github.com/nerima-lisp/cl-cli). Nix resolves these and their
transitive dependencies for you.

On terminals without 256-color support, use `--no-color` to draw each band
with a separate ASCII glyph.

## Run it without installing

```sh
nix run github:nerima-lisp/cl-nyancat/v0.1.0
```

Press <kbd>q</kbd> or <kbd>Ctrl-C</kbd> to quit.

## Build the executable

```sh
git clone https://github.com/nerima-lisp/cl-nyancat
cd cl-nyancat
nix build                     # -> ./result/bin/cl-nyancat
./result/bin/cl-nyancat --duration 5
```

For scripted runs, `--frames 120` stops after an exact number of frames.
`--width`/`-W` and `--height`/`-H` crop a centered display viewport, while the
`--min-*` and `--max-*` flags provide explicit half-open crop bounds. The
display controls can be combined with `--no-counter`, `--no-title`, or
`--no-clear` when embedding the animation in a terminal workflow.

## Use it as a library

```lisp
(asdf:load-system "cl-nyancat")

;; Take over the terminal for ten seconds, then restore it.
(cl-nyancat:run :seed 42 :duration 10)
```

The library entry point also accepts `:frames`, `:counterp`, `:titlep`,
`:clearp`, `:introp`, explicit crop bounds, and `:viewport-width`/
`:viewport-height`. Its `:width` and `:height` arguments continue to control
the animation world geometry.

`RUN` manages raw mode, the alternate screen, and cursor visibility. See the
[API reference](reference/api.md#run-key-width-height-seed-colorp-fps-duration-frames-counterp-titlep-clearp-introp-min-rows-max-rows-min-cols-max-cols-viewport-width-viewport-height-stream)
for terminal-session details.

If you only want the frames and not the terminal handling, the whole renderer
is available as a pure function:

```lisp
(let ((world (cl-nyancat:make-world :width 60 :height 20 :seed 7)))
  (dotimes (tick 100) (cl-nyancat:world-advance world))
  (write-string (cl-nyancat:world-to-string world)))
```

`WORLD-TO-STRING` returns plain text with no escape sequences and does not need
a terminal.

## Development

```sh
nix develop          # SBCL with CL_SOURCE_REGISTRY already set
nix run .#test       # run the test suite
nix flake check      # tests + formatting + paredit lint
```

Or, from a checkout with the sibling repositories beside it:

```sh
CL_SOURCE_REGISTRY=/path/to/nerima-lisp// sbcl --script run-tests.lisp
```
