{
  lib,
  stdenvNoCC,
  writeNuBin,
}:

let
  sources = import ../../../npins;
  nurl = (import sources.nurl).packages.${stdenvNoCC.hostPlatform.system}.default;
in

writeNuBin ",patch" {
  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    "${lib.makeBinPath [ nurl ]}"
  ];
} ./patch.nu
