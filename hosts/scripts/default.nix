{
  lib,
  stdenvNoCC,
  writers,
  nushell,
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
  nu-lib,
  nvd-json,
}:

let
  writeNuBin =
    name:
    writers.makeScriptWriter {
      interpreter = "${lib.getExe nushell} --no-config-file --include-path ${nu-lib}/share/nu";
      makeWrapperArgs = [
        "--prefix"
        "PATH"
        ":"
        "${lib.makeBinPath (
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
        )}"
      ];
    } "/bin/${name}";
in

writeNuBin "host-scripts" (builtins.readFile ./host-scripts.nu)
