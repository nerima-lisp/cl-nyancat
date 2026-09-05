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

The starfield, rainbow trail, and cat frame are derived from the seed and tick.
The renderer does not use `CL:*RANDOM-STATE*`. See the
[architecture notes](reference/architecture.md#design-premise) for the state
model and reproducibility details.

## Where to go next

| If you want to | Read |
| --- | --- |
| Run it for the first time | [Getting started](getting-started.md) |
| Know every flag and key | [Usage and keybindings](guide/usage.md) |
| Call it from Lisp | [API reference](reference/api.md) |
| Understand the design | [Architecture](reference/architecture.md) |
| See what is not built yet | [Roadmap](project/roadmap.md) |
