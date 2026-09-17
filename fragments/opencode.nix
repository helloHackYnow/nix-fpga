# Support fragment so unpatched, generic-Linux binaries (notably the opencode
# CLI pulled down by `npx opencode-ai@latest`) can run inside the sandbox.
{ pkgs }:

{
  name = "opencode";

  targetPkgs = p: (with p; [
    nodejs            # node + npm + npx
    cacert            # CA certs so npm/https fetches work inside the sandbox
    stdenv.cc.cc      # libstdc++ and friends
    zlib
    openssl
    curl
    icu
    glibc
  ]);

  multiPkgs = p: [ ];

  profile = ''
    export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    export NODE_EXTRA_CA_CERTS="$SSL_CERT_FILE"
  '';
}
