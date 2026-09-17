{ pkgs ? import <nixpkgs> { }, extraPkgs ? [ ], runScript ? "bash" }:

# Standalone Vivado-only environment (Xilinx tooling + general FPGA tools),
# without the Alchitry Labs or opencode fragments.
#
# Usage:
#   nix-shell ./shell-vivado.nix
(import ./default.nix { inherit pkgs; }).mkEnv {
  name = "xilinx-env";
  inherit runScript extraPkgs;
  selected = [ "vivado" "fpga-tools" ];
}
