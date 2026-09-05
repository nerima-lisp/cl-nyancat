# cl-nyancat

A grey cat riding a sprinkled pop-tart trails a six-band rainbow across a
scrolling starfield, animated live in your terminal.

```text
 .    *   --------------  ,------------,  /\_/\
    .     ++++++++++++++  | . * . * .  | ( -.- )   *
 *        ~~~~~~~~~~~~~~~~| * . * . *  | (  w  )
   .      ::::::::::::::  | . * . * .  |  \___/       .
 *        **************  | * . * . *  |        *
    .     ##############  '------------'
                            ''      ''
```

`--no-color` uses one glyph for each rainbow band: `-`, `=`, `~`, `+`, `*`,
`#`. With color enabled, all bands use `=`, and six 256-color hues distinguish
them.

It targets SBCL only. Its direct dependencies are
[cl-tty-kit](https://github.com/nerima-lisp/cl-tty-kit) for the screen, sprite
compositing and tick loop, and [cl-cli](https://github.com/nerima-lisp/cl-cli)
for the command line.

## Deterministic rendering

The starfield hash is a pure function of `(seed, column, row)` rather than a
seeded random walk. The rendered star character also depends on the tick:

- Given the same `--seed`, viewport dimensions, options, and tick sequence,
  rendering is byte-identical by construction.
- A test can assert on the state at tick 10,000 without computing the 9,999
  frames before it.
- There is no per-star object to allocate, step, or garbage-collect, so
  `WORLD-ADVANCE` is a single `INCF` and the whole world state is nine scalars.

The rainbow trail works the same way, and the cat's animation frame is a
function of the tick. Nothing in `src/` reads `CL:*RANDOM-STATE*`.

## Where to go next

| If you want to | Read |
| --- | --- |
| Run it for the first time | [Getting started](getting-started.md) |
| Know every flag and key | [Usage and keybindings](guide/usage.md) |
| Call it from Lisp | [API reference](reference/api.md) |
| Understand the design | [Architecture](reference/architecture.md) |
| See what is not built yet | [Roadmap](project/roadmap.md) |
