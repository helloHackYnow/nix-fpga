# nix-fpga

Composable [`buildFHSEnv`](https://nixos.org/manual/nixpkgs/stable/#sec-fhs-environments)
sandboxes for Xilinx Vivado and Alchitry FPGA development on NixOS.

`buildFHSEnv` sandboxes cannot be nested, so instead of importing whole
environments this repo splits the pieces into **fragments** and merges the
selected ones into a single sandbox with `lib/mk.nix`.

## Fragments

| Fragment     | Provides                                                            |
|--------------|---------------------------------------------------------------------|
| `vivado`     | Xilinx Vivado compatibility libraries + `settings64.sh`             |
| `fpga-tools` | yosys, gtkwave, Amaranth Python, OpenCL, graphviz, git/gdb, ...     |
| `alchitry`   | Alchitry Labs V2 GUI + `alchitry` CLI (bundled IceStorm toolchain)  |
| `opencode`   | node/npm/npx and CA certs so the opencode CLI runs inside the FHS   |

## Layout

```
flake.nix              # optional flake interface (pins nixpkgs)
default.nix            # non-flake entry point (this is what projects import)
shell.nix              # preset: all four fragments
shell-alchitry.nix     # preset: alchitry
shell-vivado.nix       # preset: vivado + fpga-tools
lib/mk.nix             # merges fragments into one buildFHSEnv
fragments/*.nix        # { name, targetPkgs, multiPkgs, profile }
pkgs/alchitry-labs.nix # Alchitry Labs V2 derivation
udev/99-alchitry.rules # FTDI udev rule for the Alchitry board loader
```

## Using it from another project (`shell.nix`)

Pin a commit and its tarball hash so builds are reproducible:

```nix
{ pkgs ? import <nixpkgs> { } }:
let
  nixFpga = builtins.fetchTarball {
    url = "https://github.com/helloHackYnow/nix-fpga/archive/<COMMIT_SHA>.tar.gz";
    sha256 = "sha256-...";
  };
in
(import (nixFpga + "/default.nix") { inherit pkgs; }).mkEnv {
  name = "my-project";
  selected = [ "vivado" "fpga-tools" ];   # add "alchitry" / "opencode" as needed
}
```

Get the two values after pushing:

```sh
# 1. the commit to pin
COMMIT=$(git rev-parse HEAD)

# 2. the unpacked-tarball hash as SRI (sha256-...);
nix store prefetch-file --unpack \
  "https://github.com/helloHackYnow/nix-fpga/archive/$COMMIT.tar.gz"
```

`nix store prefetch-file` prints the modern `sha256-<base64>` (SRI) form that
`builtins.fetchTarball` expects. If you use the older
`nix-prefetch-url --unpack` (which prints base32), convert it first:

```sh
nix hash convert --hash-algo sha256 --to sri <base32-hash>
```

The hash is tied to the commit: recompute it every time you bump the pin.

`mkEnv` accepts `name`, `selected`, `runScript`, `extraPkgs` and `vivadoPath`.
The sandbox is built from the caller's `pkgs`, so nixpkgs can be pinned by
whatever means the project already uses.

## Vivado path

The `vivado` fragment defaults to `$VIVADO_PATH` and falls back to
`/home/victor/opt/Xilinx/2026.1/Vivado`. Override per shell:

```sh
VIVADO_PATH=/opt/Xilinx/2026.1/Vivado nix-shell
```

or explicitly:

```nix
(import ... ).mkEnv { selected = [ "vivado" ]; vivadoPath = "/opt/Xilinx/2026.1/Vivado"; }
```

## Board access (Alchitry)

Install the FTDI udev rule once:

```sh
sudo cp udev/99-alchitry.rules /etc/udev/rules.d/
sudo udevadm control --reload
```

## Flake usage (optional)

```sh
nix develop                     # all fragments
nix develop .#alchitry          # alchitry only
nix develop .#vivado            # vivado + fpga-tools
nix build .#alchitry-labs       # the Alchitry Labs V2 package
```

Flake consumers get the pinned nixpkgs through `nix-fpga.lib.<system>.mkEnv`.

## Adding a fragment

Create `fragments/<name>.nix` returning `{ name, targetPkgs, multiPkgs?, profile }`
and register it in the `fragments` set in `default.nix`. `lib/mk.nix` dedupes
overlapping packages across fragments with `lib.unique`.
