# Roadmap

cl-nyancat is a terminal toy, not a library with downstream consumers. The bar
for adding anything is correspondingly high: it has to make the animation
better on screen, and it has to survive the
[pure-state / thin-IO split](../reference/architecture.md#pure-state-thin-io)
that makes the current version testable without a terminal.

## v0.1.0 -- shipped

- Original pop-tart cat sprite, two animation frames sharing one column grid.
- Six-band rainbow trail with a scrolling square wave.
- Deterministic starfield: a pure hash of `(seed, column, row)`, twinkling on
  its own per-star phase.
- Two-tone cat -- pink body, grey head -- from one authored sprite via
  `CAT-FRAME-PART`.
- Local nyancat display controls: `--fps`, `--duration`, `--frames`, `--seed`,
  `--width`/`-W`, `--height`/`-H`, the four crop bounds, `--intro`,
  `--no-color`, `--no-counter`, `--no-title`, `--no-clear`, `--help`, and
  `--version`.
- Quit on <kbd>q</kbd> / <kbd>Q</kbd> / <kbd>Ctrl-C</kbd>; color toggle on
  <kbd>c</kbd>.
- Live resize handling by polling, matching cl-tty-kit's own convention.
- Delivered executable via `program-op` and `nix build`.

## Considered and deliberately cut

These are recorded rather than left as silent omissions; see
[Architecture](../reference/architecture.md#deliberately-not-built) for the
reasoning in full.

| Cut | Why |
| --- | --- |
| A cat that flies in from the left | Would end "the tick is the whole state transition", for ~2s of startup animation |
| Per-glyph cat coloring (eyes, whiskers) | Needs one blit and one column map per region; the shared-grid trick stops paying |
| Music | Needs an audio dependency `DEPENDENCY_POLICY.md` would not permit here |
| Mouse input | cl-tty-kit decodes it; there is nothing to click |
| Network `--telnet` / `--skip-intro` mode | Requires a telnet server, protocol negotiation, and a network lifecycle outside the local terminal boundary |

## Possible later

Nothing here is committed to. Each would have to justify itself against the
scope discipline above.

- **A third cat frame.** Two frames read as a trot; three could read as a
  gallop. The cost is one more hand-authored sprite on the shared grid, which
  is the cheapest addition on this list.
- **`--rainbow-bands <n>`.** The band count is already a parameter everywhere
  except the palette table, which is a fixed six-entry vector. Making it a flag
  means deciding what a 3-band or 12-band rainbow's colors are, which is a
  design question rather than a code one.
- **True-color (24-bit) rainbow.** cl-tty-kit's `STYLE-FG` already accepts
  `(R G B)`, and `COLOR-GRADIENT` would give a smooth ribbon rather than six
  steps. Wants a capability probe first, so that a 256-color terminal does not
  get 24-bit escapes it will render as garbage.

## Non-goals

- Portability beyond SBCL. The org is SBCL-only; see `DEPENDENCY_POLICY.md`.
- Any runtime dependency beyond cl-tty-kit and cl-cli.
- Being a faithful pixel-for-pixel reproduction of the original nyancat. The
  art here is original by design, and staying original is a constraint rather
  than a limitation to be fixed.
