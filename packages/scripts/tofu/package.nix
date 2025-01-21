{
  lib,
  writeNuBin,
  coreutils,
  vault,
  opentofu,
  tofu-config,
}:

writeNuBin ",tofu" {
  makeWrapperArgs = [
    "--set"
    "TF_CONFIG"
    "${tofu-config}"

    "--prefix"
    "PATH"
    ":"
    "${lib.makeBinPath [
      coreutils
      opentofu
      vault
    ]}"
  ];
} ./tofu.nu
