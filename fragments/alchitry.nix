# Alchitry Labs V2 + alchitry CLI FHS fragment.
#
# The upstream release is a generic-Linux bundle whose JRE, oss-cad-suite
# (yosys / nextpnr-ice40 / icepack / Python), sv2v and tclkit all expect the
# standard FHS loader at /lib64. This fragment adds those libraries plus the
# X11/OpenGL/ALSA/USB stack the Compose desktop UI and the board loader need.
{ pkgs }:

let
  alchitry = pkgs.callPackage ../pkgs/alchitry-labs.nix { };
in
{
  name = "alchitry";

  targetPkgs = p: (with p; [
    alchitry

    # glibc / libstdc++ for the bundled generic-Linux binaries
    stdenv.cc.cc.lib
    zlib
    gmp

    # AWT + Compose desktop (Skiko) runtime
    glib
    gtk3
    libGL
    libglvnd
    mesa
    libX11
    libXext
    libXrender
    libXi
    libXtst
    libXrandr
    libXcursor
    libXxf86vm
    libXcomposite
    libXdamage
    libXfixes
    libxcb
    libxkbcommon
    fontconfig
    freetype
    alsa-lib
    cairo
    pango

    # Native file dialogs / secret storage used by the filekit-dialogs JAR
    libsecret
    dbus
    xdg-utils

    # FPGA board access (usb4java / jSerialComm)
    libusb1
    eudev
  ]);

  multiPkgs = p: [ ];

  profile = ''
    export ALCHITRY_LABS_VERSION="${alchitry.version}"

    # Alchitry Cu projects default to the proprietary Lattice iCEcube2 flow.
    # This environment ships the open-source IceStorm toolchain instead, so
    # seed the "use iCEcube2" preference to false the first time the app runs.
    # If the key already exists (you picked a toolchain in the GUI), it is
    # left untouched.
    if [ -n "''${HOME:-}" ]; then
      _alchitry_prefs="$HOME/.java/.userPrefs/com/alchitry/labs2/prefs.xml"
      if ! grep -qs 'USE_ICECUBE' "$_alchitry_prefs"; then
        mkdir -p "$(dirname "$_alchitry_prefs")"
        if [ -f "$_alchitry_prefs" ]; then
          sed -i 's#</map>#  <entry key="USE_ICECUBE" value="false"/>\n</map>#' "$_alchitry_prefs"
        else
          cat > "$_alchitry_prefs" <<'ALCHITRY_PREFS'
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE map SYSTEM "http://java.sun.com/dtd/preferences.dtd">
<map MAP_XML_VERSION="1.0">
  <entry key="USE_ICECUBE" value="false"/>
</map>
ALCHITRY_PREFS
        fi
      fi
      unset _alchitry_prefs
    fi

    echo "Alchitry (Labs ${alchitry.version}): alchitry-labs (GUI) / alchitry --help (CLI)"
    echo "Cu boards build with the bundled open-source IceStorm toolchain."
    echo "Board programming needs the FTDI udev rule (see udev/99-alchitry.rules)."
  '';
}
