{
  lib,
  stdenvNoCC,
  writeNuBin,
}:

let
  sources = import ../../npins/patched.nix;
  nurl = (import sources.nurl).packages.${stdenvNoCC.hostPlatform.system}.default;
in

writeNuBin ",patch" {
  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    "${lib.makeBinPath [ nurl ]}"
  ];
} ./patch-scripts.nu
