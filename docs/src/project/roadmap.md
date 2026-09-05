# Roadmap

cl-nyancat is a terminal application, not a library with downstream consumers. New
features should preserve the
[pure-state / thin-IO split](../reference/architecture.md#pure-state-thin-io)
that makes the current version testable without a terminal.

## v0.1.0 -- shipped

- Pop-tart cat sprite with two animation frames sharing one column grid.
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

## Out of scope

| Cut | Why |
| --- | --- |
| A cat that flies in from the left | Would end "the tick is the whole state transition", for ~2s of startup animation |
| Per-glyph cat coloring (eyes, whiskers) | Needs one blit and one column map per region; the shared grid would no longer cover these regions |
| Music | Needs an audio dependency |
| Mouse input | cl-tty-kit decodes it; there is nothing to click |
| Network `--telnet` / `--skip-intro` mode | Requires a telnet server, protocol negotiation, and a network lifecycle outside the local terminal boundary |

## Possible later

- **A third cat frame.** This would add one hand-authored sprite on the shared
  grid.
- **`--rainbow-bands <n>`.** The band count is already a parameter everywhere
  except the palette table, which is a fixed six-entry vector. Making it a flag
  means deciding what a 3-band or 12-band rainbow's colors are, which is a
  defining the palette for rainbows with other band counts.
- **True-color (24-bit) rainbow.** cl-tty-kit's `STYLE-FG` already accepts
  `(R G B)`, and `COLOR-GRADIENT` would give a smooth ribbon rather than six
  steps. Wants a capability probe first, so that a 256-color terminal does not
  receive 24-bit escape sequences it cannot render correctly.

## Non-goals

- Portability beyond SBCL. The implementation targets SBCL.
- Any runtime dependency beyond cl-tty-kit and cl-cli.
- Being a faithful pixel-for-pixel reproduction of the original nyancat.
