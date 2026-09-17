# Xilinx Vivado-specific FHS fragment.
#
# Everything here exists to make the proprietary Vivado tools run on NixOS:
# the compatibility libraries Vivado's bundled JRE/libs expect, plus a profile
# that sources Vivado's own settings64.sh.
#
# The install prefix defaults to $VIVADO_PATH and falls back to the path below;
# callers can also pass `vivadoPath` explicitly.
{ pkgs
, vivadoPath ? (let p = builtins.getEnv "VIVADO_PATH";
                in if p == "" then "/home/victor/opt/Xilinx/2026.1/Vivado" else p)
}:

let
  # Some Vivado helpers link against the non-unicode ncurses variants, and
  # nixpkgs' postFixup symlinks break inside buildFHSEnv, so ship both.
  # https://github.com/NixOS/nixpkgs/issues/218534
  ncurses' = pkgs.ncurses5.overrideAttrs (old: {
    configureFlags = old.configureFlags ++ [ "--with-termlib" ];
    postFixup = "";
  });
  ncurses6' = pkgs.ncurses6.overrideAttrs (old: {
    configureFlags = old.configureFlags ++ [ "--with-termlib" ];
    postFixup = "";
  });

  # Vivado needs libidn.so.11 but nixpkgs ships libidn.so.12.
  libidn11 = pkgs.libidn.overrideAttrs (_old: {
    src = pkgs.fetchurl {
      url = "mirror://gnu/libidn/libidn-1.34.tar.gz";
      sha256 = "sha256-Nxnil18vsoYF3zR5w4CvLPSrTpGeFQZSfkx2cK//bjw=";
    };
  });
in
{
  name = "vivado";

  targetPkgs = p: (with p; [
    # core runtime
    stdenv.cc.cc
    zlib
    gmp
    libuuid
    pixman
    libpng
    libffi
    libyaml
    expat
    sqlite
    zstd
    lsb-release

    # terminfo / ncurses compatibility
    ncurses'
    (ncurses'.override { unicodeSupport = false; })
    ncurses6'
    (ncurses6'.override { unicodeSupport = false; })

    # Vivado-specific compatibility shims
    libxcrypt-legacy
    libidn11
    libudev0-shim

    # X11 / desktop stack used by the Vivado GUI and SDK
    libXext
    libX11
    libXrender
    libXtst
    libXi
    libXft
    libxcb
    libXcomposite
    libXdamage
    libXfixes
    libXrandr
    libxkbfile
    libxkbcommon
    freetype
    fontconfig
    glib
    gtk2
    gtk3
    nss
    nspr
    dbus
    at-spi2-atk
    cups
    libdrm
    pango
    cairo
    libgbm
    alsa-lib
    libglvnd
    libsecret
  ]);

  multiPkgs = p: [ ];

  profile = ''
    export IN_XILINX_FHS_ENV=1
    export LC_NUMERIC="en_US.UTF-8"
    source ${vivadoPath}/settings64.sh
  '';
}
