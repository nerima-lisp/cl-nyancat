# Usage and keybindings

## Flags

| Flag | Type | Default | Meaning |
| --- | --- | --- | --- |
| `--fps <n>` | integer, 1-60 | `12` | Target frames per second. |
| `--duration <seconds>` | number, >= 0 | none | Stop after this long. Omitted, the animation runs until interrupted. |
| `--frames <n>`, `-f` | integer, >= 1 | none | Stop after this many frames. |
| `--seed <n>` | integer | `0` | Selects the starfield. The same seed always draws the same stars. |
| `--width <n>`, `-W` | integer, >= 1 | terminal width | Center the displayed viewport to this width. |
| `--height <n>`, `-H` | integer, >= 1 | terminal height | Center the displayed viewport to this height. |
| `--min-rows <n>`, `-r` | integer, >= 0 | `0` | Crop rows at or below this zero-based top bound. |
| `--max-rows <n>`, `-R` | integer, >= 0 | terminal height | Crop rows below this exclusive bottom bound. |
| `--min-cols <n>`, `-c` | integer, >= 0 | `0` | Crop columns at or below this zero-based left bound. |
| `--max-cols <n>`, `-C` | integer, >= 0 | terminal width | Crop columns below this exclusive right bound. |
| `--intro`, `-i` | flag | off | Print a short introduction before entering the animation. |
| `--no-color` | flag | off | Plain ASCII: one distinct glyph per rainbow band, no escape sequences for color. |
| `--no-counter`, `-n` | flag | off | Do not display the elapsed-time counter. |
| `--no-title`, `-s` | flag | off | Do not set the terminal title. |
| `--no-clear`, `-e` | flag | off | Do not clear the display between rendered frames. |
| `--help`, `-h` | flag | -- | Print usage and exit 0. |
| `--version` | flag | -- | Print the version from `cl-nyancat.asd` and exit 0. |

```sh
cl-nyancat                              # until you press q
cl-nyancat --duration 8 --fps 24        # run for eight seconds
cl-nyancat --frames 120 --no-counter    # exactly 120 frames
cl-nyancat -W 80 -H 24                  # centered 80x24 display viewport
cl-nyancat -c 4 -C 76 -r 2 -R 22        # explicit crop bounds
cl-nyancat --seed 1729                  # a different starfield
cl-nyancat --no-color --duration 3      # for a terminal without 256 colors
```

`--width`/`-W` and `--height`/`-H` size the displayed viewport; they do not
change the library animation geometry. With no explicit crop bound, each
viewport is centered in the current world. The `--min-*` and `--max-*` options
override that placement and use half-open bounds.

The local terminal mode does not provide the standard nyancat
`--telnet` or `--skip-intro` options. Those options belong to a network server
mode, while cl-nyancat remains a local terminal application.

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
is not reset, so resizing changes the visible region of the starfield and
rainbow without restarting them.

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

The same seed, terminal size, and tick sequence produce the same frames. See
[Architecture](../reference/architecture.md#design-premise) for the rendering
model.
