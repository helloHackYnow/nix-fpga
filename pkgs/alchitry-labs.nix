# Alchitry Labs V2 + alchitry CLI, repackaged from the official generic-Linux
# release tarball.
#
# The bundle is Conveyor-made: its native launchers resolve `lib/app` and
# `lib/runtime` relative to their own path and bake in `-Dapp.dir=lib/app`, so
# the whole tree is relocatable and can live untouched in the read-only store.
#
# The bundled ELF binaries (jlink JRE, oss-cad-suite, sv2v, tclkit) use the
# generic `/lib64/ld-linux-x86-64.so.2` loader, which does not exist on NixOS.
# They are therefore meant to be run inside the FHS sandbox built from
# `fragments/alchitry.nix` (see `shell.nix`). Fixup is disabled so nothing gets
# patched or stripped (stripping also corrupts the bundled Tclkit).
{ lib
, stdenv
, fetchurl
, version ? "2.0.57"
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "alchitry-labs";
  inherit version;

  src = fetchurl {
    url = "https://github.com/alchitry/Alchitry-Labs-V2/releases/download/${finalAttrs.version}/alchitry-labs-${finalAttrs.version}-linux-amd64.tar.gz";
    hash = "sha256-T696jtuzjmeLPBPl9T5lp81hc/IxQ52FfzP55KiFXBY=";
  };

  sourceRoot = "alchitry-labs-${finalAttrs.version}";

  # Do not touch the bundled binaries: the FHS environment provides /lib64,
  # and the release is already fully built.
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/opt/alchitry" "$out/bin" "$out/share"
    cp -a bin lib "$out/opt/alchitry/"
    cp -a share/. "$out/share/"

    ln -s "$out/opt/alchitry/bin/alchitry" "$out/bin/alchitry"
    ln -s "$out/opt/alchitry/bin/alchitry-labs" "$out/bin/alchitry-labs"

    runHook postInstall
  '';

  meta = {
    description = "Write, build, and load projects for Alchitry FPGA development boards";
    homepage = "https://alchitry.com/";
    downloadPage = "https://github.com/alchitry/Alchitry-Labs-V2";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "alchitry-labs";
  };
})
