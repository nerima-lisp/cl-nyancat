# cl-nyancat

[![CI](https://github.com/nerima-lisp/cl-nyancat/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/nerima-lisp/cl-nyancat/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Documentation](https://img.shields.io/badge/docs-MkDocs%20Material-0a7a5a)](https://nerima-lisp.github.io/cl-nyancat/)

A grey cat riding a sprinkled pop-tart trails a six-band rainbow across a
scrolling starfield, animated live in your terminal via
[cl-tty-kit](https://github.com/nerima-lisp/cl-tty-kit). Every sprite is
original art authored for this repository -- this is not a port of any existing
nyancat implementation. Targets SBCL on x86_64-linux and aarch64-darwin.

Full documentation is published at <https://nerima-lisp.github.io/cl-nyancat/>.
The source for that site lives in [docs/src/](docs/src/).

## Quick Start

```lisp
(asdf:load-system "cl-nyancat")

(cl-nyancat:run :seed 42 :duration 10)
;; Fills the current terminal for ten seconds. Press q or Ctrl-C to quit
;; early, c to toggle color.
```

Or, once built, from the command line:

```sh
cl-nyancat --fps 24 --seed 42
cl-nyancat --frames 120 --no-counter
cl-nyancat -W 80 -H 24
```

The command-line interface is declared through `cl-cli`; see the
[usage guide](https://nerima-lisp.github.io/cl-nyancat/guide/usage/) for the
full display, crop, and terminal-control option set.

## Install

As a command, from a checkout:

```sh
nix build              # -> ./result/bin/cl-nyancat
./result/bin/cl-nyancat --duration 5
```

Or without cloning: `nix run github:nerima-lisp/cl-nyancat`.

As a library, from another flake:

```nix
# flake.nix
inputs.cl-nyancat = {
  url = "github:nerima-lisp/cl-nyancat/v0.1.0";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Note the pinned tag. Consumers inside this org must pin a release tag rather
than follow the default branch. On a `lispDependencies` edge, read
`cl-nyancat.packages.<system>.cl-nyancat` -- `packages.default` is the
delivered binary, not the ASDF system.

## Documentation

- [Getting started](https://nerima-lisp.github.io/cl-nyancat/getting-started/)
- [Usage and keybindings](https://nerima-lisp.github.io/cl-nyancat/guide/usage/)
- [API reference](https://nerima-lisp.github.io/cl-nyancat/reference/api/)
- [Architecture](https://nerima-lisp.github.io/cl-nyancat/reference/architecture/) --
  the three-layer painter, the pure-state/thin-IO split, and what this v1
  deliberately left out
- [Roadmap](https://nerima-lisp.github.io/cl-nyancat/project/roadmap/)

## Development

```sh
nix develop          # SBCL with CL_SOURCE_REGISTRY already set
nix build            # -> ./result/bin/cl-nyancat
nix run .#test       # run the test suite
nix flake check      # tests + formatting + docs + paredit lint, the same gate CI uses
nix fmt              # format Nix sources (treefmt)
nix build .#checks.$(nix eval --raw --expr builtins.currentSystem).coverage --no-link --print-out-paths
                     # sb-cover HTML report for src/; open cover-index.html
                     # from the printed path. No pass/fail threshold -- see
                     # flake.nix.
```

Tests live in `t/` and run under [cl-weave](https://github.com/nerima-lisp/cl-weave).
The starfield is deterministic for a given `--seed`; `nix flake check` also
runs structural Lisp lint and the documentation checks.

## Contributing

See the org-wide [CONTRIBUTING](https://github.com/nerima-lisp/.github/blob/main/CONTRIBUTING.md)
guide and the [package standard](https://github.com/nerima-lisp/.github/blob/main/PACKAGE_STANDARD.md).

## Support

See [SUPPORT](https://github.com/nerima-lisp/.github/blob/main/SUPPORT.md).

## License

MIT. See [LICENSE](LICENSE).
