{
  pkgs,
  lib,
  stdenvNoCC,
  nushell,
  makeWrapper,
  coreutils,
  openssh,
  vault,
  attic-client,
  colmena,
  nix-output-monitor,
  nvd,
  nettools,
  nix,
  systemd,
}:

let
  nvd-json = import ../../apps/nvd-json { inherit pkgs; };
in

stdenvNoCC.mkDerivation {
  pname = "host-scripts";
  version = "0.0.1";

  src = ./.;

  buildInputs = [ nushell ];

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    install -Dv host-scripts.nu $out/bin/host-scripts

    wrapProgram $out/bin/host-scripts \
      --prefix PATH : ${
        lib.makeBinPath (
          [
            coreutils
            openssh
            vault
            attic-client
            colmena
            nix-output-monitor
            nvd
            nvd-json
            nix
          ]
          ++ lib.optionals stdenvNoCC.isLinux [
            nettools
            systemd
          ]
        )
      }
  '';

  meta.mainProgram = "host-scripts";
}
