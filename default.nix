{ pkgs ? import <nixpkgs> { } }:

# Non-flake entry point for importing this environment from another project's
# `shell.nix`, e.g.:
#
#   let
#     nixFpga = builtins.fetchTarball {
#       url = "https://github.com/USER/nix-fpga/archive/<COMMIT>.tar.gz";
#       sha256 = "sha256-...";
#     };
#   in
#   (import (nixFpga + "/default.nix") { inherit pkgs; }).mkEnv {
#     name = "my-project";
#     selected = [ "vivado" "fpga-tools" ];
#   }
#
# The `pkgs` used to build the sandbox is the caller's, so a project can pin
# nixpkgs however it likes (channel, fetchTarball, npins, flake input).
let
  inherit (pkgs) lib;
  mk = import ./lib/mk.nix { inherit pkgs; };
in
{
  inherit mk;

  # Build one buildFHSEnv from the named fragments in ./fragments.
  #   selected  - fragment names to merge
  #   extraPkgs - extra packages appended to the sandbox
  #   runScript - shell launched by the sandbox (default "bash")
  #   vivadoPath - overrides $VIVADO_PATH / the built-in default for the
  #                "vivado" fragment
  mkEnv = { name ? "fpga-env"
          , selected ? [ "fpga-tools" ]
          , runScript ? "bash"
          , extraPkgs ? [ ]
          , vivadoPath ? null
          }:
    let
      fragments = {
        vivado = import ./fragments/vivado.nix
          ({ inherit pkgs; } // lib.optionalAttrs (vivadoPath != null) { inherit vivadoPath; });
        fpga-tools = import ./fragments/fpga-tools.nix { inherit pkgs; };
        alchitry = import ./fragments/alchitry.nix { inherit pkgs; };
        opencode = import ./fragments/opencode.nix { inherit pkgs; };
      };
    in
    mk {
      inherit name runScript extraPkgs;
      fragments = map (n: fragments.${n}) selected;
    };
}
