# Usage and keybindings

## Flags

| Flag | Type | Default | Meaning |
| --- | --- | --- | --- |
| `--fps <n>` | integer, 1-60 | `12` | Target frames per second. |
| `--duration <seconds>` | number, >= 0 | none | Stop after this long. Omitted, the animation runs until interrupted. |
| `--seed <n>` | integer | `0` | Selects the starfield. The same seed always draws the same stars. |
| `--no-color` | flag | off | Plain ASCII: one distinct glyph per rainbow band, no escape sequences for color. |
| `--help`, `-h` | flag | -- | Print usage and exit 0. |
| `--version` | flag | -- | Print the version from `cl-nyancat.asd` and exit 0. |

```sh
cl-nyancat                              # until you press q
cl-nyancat --duration 8 --fps 24        # eight seconds, smoother
cl-nyancat --seed 1729                  # a different starfield
cl-nyancat --no-color --duration 3      # for a terminal without 256 colors
```

## Keys

| Key | Effect |
| --- | --- |
| <kbd>q</kbd> / <kbd>Q</kbd> | Quit. |
| <kbd>Ctrl-C</kbd> | Quit. |
| <kbd>c</kbd> / <kbd>C</kbd> | Toggle color on and off, without restarting. |

!!! note "Why Ctrl-C is a keystroke here"
    The animation runs with the terminal in raw mode, which clears `ISIG`, so
    Ctrl-C never becomes a `SIGINT` for this process. cl-tty-kit's decoder
    reports it as a `:SPECIAL` key event with code `:CONTROL-C`, and
    `QUIT-KEY-EVENT-P` matches on that. It is a normal quit, not a kill: the
    terminal is restored on the way out exactly as it is for `q`.

## Resizing

Resize the terminal while it is running and the animation follows. cl-tty-kit
polls `TERMINAL-SIZE` rather than trapping `SIGWINCH`, so cl-nyancat checks the
size once per tick and re-places the cat when it has changed. The tick counter
is not reset, so the starfield and rainbow simply reveal more or less of
themselves rather than restarting.

A terminal too small for the whole sprite still renders: the cat is pinned to
the top-left corner and clipped, rather than disappearing or signalling.

## Colors

With color on, the six rainbow bands are 256-color palette entries -- red,
orange, yellow, green, blue, violet -- and every band shares the `=` glyph, so
the trail reads as one ribbon. The pop-tart body is pink and the cat's head is
grey; they are drawn as two separate blits of one authored sprite, because
cl-tty-kit's `SPRITE-BLIT` applies a single style per call.

With `--no-color` (or after pressing <kbd>c</kbd>), each band takes its own
glyph instead -- `-`, `=`, `~`, `+`, `*`, `#` -- since there is no color left
to tell them apart. Stars twinkle through `.`, `+` and `*` in either mode.

## Reproducibility

Two runs with the same `--seed` and the same terminal size draw identical
frames at identical ticks. This is not a "we were careful" guarantee: nothing
in `src/` reads `CL:*RANDOM-STATE*`, so there is no generator whose state could
diverge. See [Architecture](../reference/architecture.md) for how the starfield
gets its apparent randomness from a hash instead.
