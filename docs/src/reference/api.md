# API reference

The symbols below are the public API of the `CL-NYANCAT` package.

## Application entry points

### `run &key width height seed colorp fps duration frames counterp titlep clearp introp min-rows max-rows min-cols max-cols viewport-width viewport-height stream`

Animate the cat in the real terminal; returns the final `WORLD`. `WIDTH` and
`HEIGHT` default to the detected terminal size and are then kept up to date
automatically. `SEED` selects the starfield (default `0`); `COLORP` false
renders plain ASCII; `FPS` is the target frame rate (default `12`); `DURATION`,
in seconds, and `FRAMES`, when supplied, stop the animation at the earlier
limit. Without either limit the loop runs until <kbd>q</kbd>, <kbd>Q</kbd> or
<kbd>Ctrl-C</kbd>. `COUNTERP`, `TITLEP`, `CLEARP`, and `INTROP` control the
timer, terminal title, per-frame clearing, and introductory message. `MIN-*`
and `MAX-*` are zero-based half-open crop bounds. `VIEWPORT-WIDTH` and
`VIEWPORT-HEIGHT` request centered crop dimensions unless an explicit minimum
bound is supplied; they affect display only, not `WORLD`'s geometry. `STREAM`
is the output stream used for the terminal session.

Puts the terminal into raw mode on the alternate screen with the cursor hidden,
and restores all three on the way out.

### `*app*`

The declarative `cl-cli` specification for the `cl-nyancat` command.

### `main`, `image-entry-point`

Toplevels for `sbcl --script` and for the delivered executable respectively.
Both parse the process argv against `*APP*` and exit with its result code.
`IMAGE-ENTRY-POINT` is named by `:entry-point` in `cl-nyancat.asd`.

## World state

### `make-world &key width height seed colorp max-ticks`

Create a `WORLD`. `MAX-TICKS`, when supplied, is the tick at which
`WORLD-FINISHED-P` becomes true; `NIL` runs until interrupted. A non-positive
`WIDTH` or `HEIGHT` signals `NYANCAT-INVALID-DIMENSIONS`.

Accessors: `world-width` `world-height` `world-tick` `world-seed`
`world-colorp` `world-quitp` `world-max-ticks` `world-cat-x` `world-cat-y`,
plus the predicate `world-p`. All are `SETF`-able.

### `world-resize world width height`

Resize in place and re-place the cat; returns `WORLD`. The tick is **not**
reset -- the layers are functions of it, so they reveal more or less of
themselves at the new size. Signals `NYANCAT-INVALID-DIMENSIONS` on a
non-positive dimension.

## Simulation

### `world-advance world`

Advance by one tick in place; returns `WORLD`. The tick is the whole
transition.

### `world-finished-p world`

True when the animation should stop: `WORLD-QUITP` is set, or `WORLD-MAX-TICKS`
has been reached. This is the `STOP` predicate handed to
`cl-tty-kit:TICK-LOOP-RUN-REALTIME`.

### `world-cat-frame world`

The cat sprite text to draw at the world's current tick.

## Input

### `quit-key-event-p event`

True when a decoded `cl-tty-kit` `KEY-EVENT` should stop the animation:
<kbd>q</kbd>, <kbd>Q</kbd>, or the `:SPECIAL` `:CONTROL-C` event Ctrl-C decodes
to under raw mode.

### `world-apply-key-event world event`, `world-apply-key-events world events`

Apply decoded key events to `WORLD`; return `WORLD`. Unbound keys are ignored.

## Rendering

### `draw-world screen world &key min-cols max-cols min-rows max-rows`

Clear `SCREEN` and paint the three layers back to front, optionally projecting
a cropped source region into the screen origin; returns `SCREEN`. The
individual layers are also exported: `draw-stars`, `draw-rainbow`, `draw-cat`.

### `world-to-string world`

The current frame as plain text -- `WORLD-HEIGHT` rows joined by newlines, no
styling, no escape sequences. Allocates its own screen. This is the testable
render path.

### `render-frame renderer world &key counterp fps clearp min-cols max-cols min-rows max-rows`

Draw onto `RENDERER`'s back buffer and return `RENDERER-RENDER`'s diff string.
`COUNTERP` adds the elapsed-time counter, `CLEARP` prepends a full-screen clear,
and the crop bounds are passed to `DRAW-WORLD`. Returned rather than printed,
so the caller owns the stream.

## Starfield

### `star-hash seed column row`

A well-mixed non-negative 32-bit integer for one world cell. A hash, not a
generator: no state, negative coordinates fine.

### `star-present-p seed column row`

True when that world cell holds a star -- roughly one in `+STAR-DENSITY+`.

### `star-char-at seed screen-column row tick`

`(VALUES CHAR PHASE)` for the star visible at a screen cell, or `NIL` when
there is none. The world column shown is `SCREEN-COLUMN + TICK`, which is what
makes the field scroll.

## Rainbow

### `rainbow-wave-offset column tick`

How many rows the trail's top edge is pushed down at `COLUMN`: `0` or
`+RAINBOW-WAVE-AMPLITUDE+`.

### `rainbow-band-at column row cat-x cat-y tick`

The band index covering a cell, or `NIL`. Counted from `0` at the top. Never
covers a cell at or right of `CAT-X`.

## Palette

`+rainbow-band-count+` (6), and the accessors `rainbow-band-style`,
`rainbow-band-char`, `star-style`, `cat-style`. Each takes the world's `COLORP`
flag and returns `NIL` for plain-ASCII mode, which `SPRITE-BLIT` and
`SCREEN-PUT-CELL` already read as "unstyled". A band index outside
`[0, +RAINBOW-BAND-COUNT+)` signals `NYANCAT-INVALID-BAND`.

## Cat sprite

`+cat-frame-count+`, `cat-frame` (index, taken modulo the count),
`cat-frame-for-tick`, `cat-art-width`, `cat-art-height`, and `cat-frame-part`.
`CAT-FRAME-PART` supports the two-blit scheme described in
[Architecture](architecture.md#two-tone-cat-from-one-sprite).

## Sprite geometry

`split-sprite-lines`, `sprite-dimensions` (returns `(VALUES WIDTH HEIGHT)`),
`sprite-width`, `sprite-height`, `clamp`, and:

### `sprite-row-span line`

`(VALUES START END)`, the half-open column range `LINE` occupies -- first
non-blank character to one past the last. Both `0` for a blank or empty line.
This is the silhouette mask that makes an irregular sprite opaque without a
second hand-authored drawing.

## Conditions

- `nyancat-error` -- base condition; catches all of the below.
- `nyancat-invalid-dimensions` -- readers
  `nyancat-invalid-dimensions-width`, `nyancat-invalid-dimensions-height`.
- `nyancat-invalid-band` -- reader `nyancat-invalid-band-index`.
