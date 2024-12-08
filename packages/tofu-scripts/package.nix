{
  lib,
  oldpkgs,
  writeNuBin,
  coreutils,
  vault,
}:

let
  inherit (import ../../terraform { pkgs = oldpkgs; }) opentofu terraformConfiguration;
in

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
