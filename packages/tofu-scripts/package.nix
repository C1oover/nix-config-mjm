{
  lib,
  writeNuBin,
  coreutils,
  vault,
  opentofu,
  tofu-config,
}:

writeNuBin "tofu-scripts" {
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
} ./tofu-scripts.nu
