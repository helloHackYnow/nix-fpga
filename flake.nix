{
  description = "Composable buildFHSEnv dev environments for Alchitry / Xilinx Vivado FPGA work on NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
    in
    {
      # Same composition API as ./default.nix, bound to the flake's pinned
      # nixpkgs. Use it from another flake with:
      #
      #   outputs = { self, nixpkgs, nix-fpga }: {
      #     devShells.x86_64-linux.default =
      #       nix-fpga.lib.x86_64-linux.mkEnv {
      #         name = "my-project";
      #         selected = [ "vivado" "fpga-tools" ];
      #       };
      #   };
      lib = forAllSystems (pkgs: import ./default.nix { inherit pkgs; });

      packages = forAllSystems (pkgs: {
        alchitry-labs = pkgs.callPackage ./pkgs/alchitry-labs.nix { };
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.alchitry-labs;
      });

      # FHS sandboxes. `nix develop` enters them via their shellHook.
      devShells = forAllSystems (pkgs: {
        default = import ./shell.nix { inherit pkgs; };
        alchitry = import ./shell-alchitry.nix { inherit pkgs; };
        vivado = import ./shell-vivado.nix { inherit pkgs; };
      });
    };
}
