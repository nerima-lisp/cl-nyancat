# Getting started

## Requirements

SBCL. Nothing else is needed at runtime: cl-nyancat depends only on
[cl-tty-kit](https://github.com/nerima-lisp/cl-tty-kit) and
[cl-cli](https://github.com/nerima-lisp/cl-cli), both of which are sibling
packages in this org, and both of which Nix resolves for you.

A terminal with 256-color support gives the intended rainbow. One without it
should be run with `--no-color`, which draws each band with its own ASCII
glyph instead.

## Run it without installing

```sh
nix run github:nerima-lisp/cl-nyancat
```

Press <kbd>q</kbd> or <kbd>Ctrl-C</kbd> to quit.

## Build the executable

```sh
git clone https://github.com/nerima-lisp/cl-nyancat
cd cl-nyancat
nix build                     # -> ./result/bin/cl-nyancat
./result/bin/cl-nyancat --duration 5
```

`nix build` reads the `:build-operation` / `:build-pathname` / `:entry-point`
keys already declared in `cl-nyancat.asd`, so
`(asdf:operate 'asdf:program-op "cl-nyancat")` produces the same binary.

## Use it as a library

```lisp
(asdf:load-system "cl-nyancat")

;; Take over the terminal for ten seconds, then restore it.
(cl-nyancat:run :seed 42 :duration 10)
```

`RUN` puts the terminal into raw mode on the alternate screen with the cursor
hidden, and restores all three on the way out -- including when the animation
is interrupted.

If you only want the frames and not the terminal handling, the whole renderer
is available as a pure function:

```lisp
(let ((world (cl-nyancat:make-world :width 60 :height 20 :seed 7)))
  (dotimes (tick 100) (cl-nyancat:world-advance world))
  (write-string (cl-nyancat:world-to-string world)))
```

`WORLD-TO-STRING` allocates its own screen, paints the three layers onto it and
returns plain text with no escape sequences. It needs no terminal, which is why
it is what the test suite asserts on.

## Development

```sh
nix develop          # SBCL with CL_SOURCE_REGISTRY already set
nix run .#test       # run the test suite
nix flake check      # tests + formatting + docs + paredit lint
```

Or, from a checkout with the sibling repositories beside it:

```sh
CL_SOURCE_REGISTRY=/path/to/nerima-lisp// sbcl --script run-tests.lisp
```
