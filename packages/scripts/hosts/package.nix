{
  lib,
  writeNuBin,
  vault,
  attic-client,
}:

writeNuBin ",hosts" {
  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    "${lib.makeBinPath [
      vault
      attic-client
    ]}"
  ];
} ./hosts.nu
