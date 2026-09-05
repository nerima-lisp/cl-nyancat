# cl-nyancat

[![CI](https://github.com/nerima-lisp/cl-nyancat/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/nerima-lisp/cl-nyancat/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Documentation](https://img.shields.io/badge/docs-MkDocs%20Material-0a7a5a)](https://nerima-lisp.github.io/cl-nyancat/)

cl-nyancat is a Common Lisp terminal animation built on
[cl-tty-kit](https://github.com/nerima-lisp/cl-tty-kit). It targets SBCL on
x86_64-linux and aarch64-darwin.

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

Pin a release tag rather than following the default branch. On a
`lispDependencies` edge, read
`cl-nyancat.packages.<system>.cl-nyancat` -- `packages.default` is the
delivered binary, not the ASDF system.

## Documentation

- [Getting started](https://nerima-lisp.github.io/cl-nyancat/getting-started/)
- [Usage and keybindings](https://nerima-lisp.github.io/cl-nyancat/guide/usage/)
- [API reference](https://nerima-lisp.github.io/cl-nyancat/reference/api/)
- [Architecture](https://nerima-lisp.github.io/cl-nyancat/reference/architecture/)
- [Roadmap](https://nerima-lisp.github.io/cl-nyancat/project/roadmap/)

## Development

```sh
nix develop
nix build
nix run .#test
nix flake check
nix fmt
```

Tests live in `t/` and run under [cl-weave](https://github.com/nerima-lisp/cl-weave).

## Contributing

See the org-wide [CONTRIBUTING](https://github.com/nerima-lisp/.github/blob/main/CONTRIBUTING.md)
guide and the [package standard](https://github.com/nerima-lisp/.github/blob/main/PACKAGE_STANDARD.md).

## Support

See [SUPPORT](https://github.com/nerima-lisp/.github/blob/main/SUPPORT.md).

## License

MIT. See [LICENSE](LICENSE).
