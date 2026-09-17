# Compose several FHS fragments into a single buildFHSEnv sandbox.
#
# buildFHSEnv environments cannot be nested, so "importing" one environment
# into another means merging their package lists and shell profiles and
# building exactly one sandbox. Each fragment under ../fragments/ is a pure
# description:
#
#   { name, targetPkgs, multiPkgs, profile }
#
# and this file is the only place that actually calls buildFHSEnv.
{ pkgs ? import <nixpkgs> { } }:

{ name ? "fpga-env"
, runScript ? "bash"
, fragments
, extraPkgs ? [ ]
}:

let
  inherit (pkgs) lib;
in
(pkgs.buildFHSEnv {
  inherit name runScript;

  # lib.unique keeps overlapping X11/GTK/glibc packages from different
  # fragments from colliding inside the generated buildEnv.
  targetPkgs = p: lib.unique (lib.concatMap (f: f.targetPkgs p) fragments ++ extraPkgs);
  multiPkgs = p: lib.unique (lib.concatMap (f: (f.multiPkgs or (_: [ ])) p) fragments);
  profile = lib.concatStringsSep "\n" (map (f: f.profile) fragments);
}).env
