{
  lib,
  writeNuBin,
  coreutils,
  vault,
  opentofu,
  terraformConfiguration,
}:

writeNuBin "tofu-scripts" {
  makeWrapperArgs = [
    "--set"
    "TF_CONFIG"
    "${terraformConfiguration}"

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
