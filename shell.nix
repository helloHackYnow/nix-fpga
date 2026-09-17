{ pkgs ? import <nixpkgs> { } }:

# Master FPGA development environment.
#
# buildFHSEnv environments cannot be nested, so this composes the FHS
# fragments in ./fragments/ into a single sandbox:
#
#   vivado     - Xilinx Vivado compatibility libs + settings64.sh
#   fpga-tools - yosys, gtkwave, Amaranth Python, OpenCL, git/gdb, ...
#   alchitry   - Alchitry Labs V2 GUI + alchitry CLI
#   opencode   - node/npx so the opencode CLI keeps working here
#
# Usage:
#   nix-shell            # loaded automatically by ./.envrc (direnv)
#   nix-shell ./shell.nix
(import ./default.nix { inherit pkgs; }).mkEnv {
  name = "fpga-env";
  selected = [ "vivado" "fpga-tools" "alchitry" "opencode" ];
}
