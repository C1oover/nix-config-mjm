{
  lib,
  stdenvNoCC,
  writeNuBin,
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
  nvd-json,
}:

writeNuBin "host-scripts" {
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
} ./host-scripts.nu
