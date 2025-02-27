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
  dippy,
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
        dippy
      ]
      ++ lib.optionals stdenvNoCC.isLinux [
        nettools
        systemd
      ]
    )}"
  ];
} ./hosts.nu
