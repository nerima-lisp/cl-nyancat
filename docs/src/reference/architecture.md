# Architecture

## The one decision everything follows from

**Nothing in `src/` reads `CL:*RANDOM-STATE*`.**

A screensaver normally seeds a generator and walks it: each frame consumes
random numbers, so frame *N* is only reachable by producing frames 0 through
*N-1*. cl-asciiquarium works that way and pays for it with a test suite that
has to bind `SB-EXT:SEED-RANDOM-STATE` around every scenario.

cl-nyancat instead makes each cell's contents a **pure function of its
coordinates and the tick**:

```lisp
(star-present-p seed column row)   ; -> a hash, not a draw
(rainbow-band-at column row cat-x cat-y tick)
(cat-frame-for-tick tick)
```

`STAR-HASH` is the lowbias32 integer finalizer over the three coordinates
combined with large odd multipliers. It looks random and is not: the same
arguments always give the same result, in any image, in any order, with no
state carried between calls.

Three consequences, and they are the reason the rest of the design is as small
as it is:

1. **`WORLD` is nine scalars.** There is no star list, no particle pool, no
   trail buffer -- nothing for the layers to live in, because they are
   computed on demand.
2. **`WORLD-ADVANCE` is one `INCF`.** The entire state transition is the tick.
   `t/update-test.lisp` asserts that advancing 500 times and simply *setting*
   the tick to 500 render identically; if hidden state ever creeps in, that
   test fails.
3. **Determinism is structural.** `--seed 42` renders byte-identically
   everywhere, not because the tests are disciplined but because there is no
   generator whose state could diverge.

## Scrolling without motion

The cat does not move. The starfield is fixed in *world* space and the viewport
advances one column per tick, so screen column `x` at tick `t` shows world
column `x + t`. The rainbow's square wave reads the world column the same way,
which is what keeps the two layers from drifting apart -- a property
`t/rainbow-test.lisp` asserts directly.

## Layers

`DRAW-WORLD` clears the screen and paints three layers back to front. Paint
order alone establishes layering; there is no z-buffer and no sort.

```text
  starfield   every cell, ~1 in 29 occupied      draw-stars
  rainbow     every column left of the cat       draw-rainbow
  cat         the sprite's own silhouette        draw-cat
```

### Making an irregular sprite opaque

cl-tty-kit's `SPRITE-BLIT` treats every `#\Space` as **transparent** -- that is
what lets a non-rectangular sprite composite over a background. But the cat's
*interior* is mostly spaces, so a naive blit would let the starfield twinkle
inside the pop-tart and run the rainbow straight across the cat's face.

Blanking the sprite's whole bounding box instead would punch a rectangular hole
in the starfield around the head.

`DRAW-CAT` uses the sprite's own silhouette as the mask. For each row,
`SPRITE-ROW-SPAN` returns the half-open range from the first non-blank
character to one past the last; only that range is blanked before the art is
blitted over it. Leading and trailing blanks stay outside the span and stay
transparent; blanks *enclosed between* glyphs are inside it and become opaque.
No second hand-authored mask has to be kept in sync with the art.

### Two-tone cat from one sprite

`SPRITE-BLIT` applies one style per call, and the cat is pink and grey. Rather
than carry two hand-drawn sprites per frame, both frames share one column grid
(documented in `src/art-cat.lisp`'s header) and `CAT-FRAME-PART` splits a frame
at `+CAT-HEAD-COLUMN+`, blanking the other side. Two blits at the same position
reassemble the whole cat, and because a blanked column is a `#\Space` and
therefore transparent, the second blit does not erase the first.

## Pure state, thin I/O

The split cl-tty-kit's `tick-loop.lisp` describes is followed literally:

| Pure -- no clock, no terminal, no I/O | Real I/O |
| --- | --- |
| `geometry` `palette` `art-cat` `starfield` `rainbow` `world` `update` `input` `timing` | `app` |
| `render` (fills a `SCREEN`, returns a string) | `cli` (`UIOP:QUIT`) |

`src/app.lisp` is the only file that touches a real terminal, and the only file
in `src/` with no corresponding test in `t/` -- by design. It composes
CL-TTY-KIT's public `MAKE-STREAM-INPUT-POLLER`, `MAKE-TERMINAL-SIZE-POLLER`,
and tick-loop `:POLL` callback instead of maintaining local input decoding or
resize polling. What remains is terminal handling that a test would have to
supply a terminal for; everything it calls is tested on its own.

`RENDER-FRAME` is the boundary: it fills the renderer's back buffer and
*returns* the escape-sequence diff rather than printing it, so the tick loop
owns the stream. `WORLD-TO-STRING` is the same painter with styling dropped,
which is what the test suite asserts on.

### Viewport projection

The animation world and the displayed viewport are separate concerns. `RUN`
keeps the detected terminal dimensions as the world geometry, then passes
zero-based half-open crop bounds to `DRAW-WORLD`. `--width`/`-W` and
`--height`/`-H` resolve to centered viewport bounds; explicit `--min-*` and
`--max-*` values take precedence. Rendering translates the selected source
region to screen origin, so the pure painter and the live terminal path share
the same crop semantics.

## Conditions

`NYANCAT-ERROR` is the base; `NYANCAT-INVALID-DIMENSIONS` and
`NYANCAT-INVALID-BAND` inherit from it, so one `HANDLER-CASE` clause catches
everything this package signals. Both carry readers for the offending value and
a `:report`.

Both share one shape -- an `:initarg`/`:reader` pair per offending value, plus
a report built only from those readers -- so `src/conditions.lisp` defines them
through one internal macro, `DEFINE-NYANCAT-CONDITION`, rather than repeating
`DEFINE-CONDITION`'s boilerplate twice. It is not exported: it exists to author
this package's own two conditions, not as a public tool for other packages to
build their own condition hierarchies with.

## Testing

The test suite combines example-based `it` cases with `it-property` cases built
on `cl-weave`'s generators where a round-trip or bounds invariant is the useful
contract -- `CLAMP`'s bound, the `CAT-FRAME-PART` body/head split's
decompose-recompose round trip, `STAR-HASH`'s purity and 32-bit range, and
`RAINBOW-BAND-AT`'s index range all hold for generated inputs. The same suite
also covers the timing helper's positive-duration invariant and deterministic
rendering, rather than asserting only hand-picked examples.

The `cl-weave` runner is configured with `:PASS-WITH-NO-TESTS NIL`, so an empty
or accidentally undiscovered test system fails instead of reporting success.
The sb-cover report remains an honest measurement: the live terminal loop and
CLI process boundary are not given fake unit seams, and load-time forms can be
counted separately from executable pure logic. Coverage should increase when
new testable logic is added, without excluding those boundaries to manufacture
100%.

## Deliberately not built

Following cl-asciiquarium's practice of naming what was cut rather than quietly
shipping less:

- **A moving cat.** The cat is stationary and the world scrolls past it. A
  fly-in from the left edge was considered and dropped: it costs a position
  slot and a clamp in `WORLD-ADVANCE`, which would end the "the tick is the
  whole transition" property that `t/update-test.lisp` pins down, in exchange
  for about two seconds of animation at startup.
- **Per-glyph cat coloring.** The cat is two regions, not five. A whiskers /
  eyes / nose / mouth split would need one blit per region and a per-region
  column map that the shared grid trick no longer covers.
- **Music.** Out of scope for a terminal toy in this org; it would need an
  audio dependency, which `DEPENDENCY_POLICY.md` would not permit for this.
- **Mouse input.** cl-tty-kit decodes it, but there is nothing here to click.
- **Network telnet mode.** The standard nyancat `--telnet` and
  `--skip-intro` options require a listening socket, telnet protocol
  negotiation, terminal-type handling, and a server lifecycle. cl-nyancat
  deliberately remains a local terminal process; its local `--intro` option
  does not imply a network mode.
