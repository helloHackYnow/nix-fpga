# General FPGA / hardware development tooling (not Vivado-specific).
{ pkgs }:

let
  # Python toolchain for Amaranth-based flows and editor integration.
  pythonEnv = pkgs.python313.withPackages (ps: with ps; [
    amaranth
    amaranth-boards
    llvmlite
    python-lsp-server
    pytest
    black
    sphinx
  ]);

  # GTKWave 3.3.127/128 from nixpkgs links against the external `judy` library
  # (via `--enable-judy`), which makes it abort with "buffer overflow detected"
  # (`__strcpy_chk` in `JudySLIns` during `vcd_build_symbols`) on ANY VCD with a
  # hierarchy depth >= 2. Use GTKWave's bundled Judy instead.
  gtkwave = pkgs.gtkwave.overrideAttrs (old: {
    buildInputs = pkgs.lib.filter (x: (x.pname or "") != "judy") (old.buildInputs or [ ]);
    configureFlags = pkgs.lib.filter (f: f != "--enable-judy") (old.configureFlags or [ ]);
  });
in
{
  name = "fpga-tools";

  targetPkgs = p: (with p; [
    pythonEnv
    yosys
    gtkwave

    # OpenCL headers/loader for Xilinx examples
    opencl-clhpp
    ocl-icd
    opencl-headers

    # Build / utilities
    graphviz
    (lib.hiPrio gcc)
    unzip
    nettools
    git
    gdb
    bash
    coreutils
  ]);

  multiPkgs = p: [ ];

  profile = '''';
}
