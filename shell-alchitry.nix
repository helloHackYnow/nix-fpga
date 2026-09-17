{ pkgs ? import <nixpkgs> { } }:

# Standalone Alchitry Labs V2 + alchitry CLI environment, without the Vivado
# or opencode fragments.
#
# Usage:
#   nix-shell ./shell-alchitry.nix
(import ./default.nix { inherit pkgs; }).mkEnv {
  name = "alchitry-env";
  selected = [ "alchitry" ];
}
