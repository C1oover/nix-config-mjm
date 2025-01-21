{
  lib,
  stdenvNoCC,
  writeNuBin,
  coreutils,
  openssh,
  vault,
  attic-client,
  nix-output-monitor,
  nvd,
  nettools,
  nix,
  systemd,
  nvd-json,
  nixos-deploy,
}:

writeNuBin ",hosts" {
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
        nix-output-monitor
        nvd
        nvd-json
        nix
        nixos-deploy
      ]
      ++ lib.optionals stdenvNoCC.isLinux [
        nettools
        systemd
      ]
    )}"
  ];
} ./hosts.nu
