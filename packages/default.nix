{
  inputs ? import ../npins,
  pkgs ? import inputs.nixos { config.allowUnfree = true; },
}:
let
  callPackage = pkgs.lib.callPackageWith (pkgs // packages);
  packages = {
    cliraop = callPackage ./cliraop.nix { };
    homelab = callPackage ../apps/homelab/package.nix { };
    linkding = callPackage ./linkding.nix { };
    mautrix-slack = callPackage ./mautrix-slack.nix { };
    pragmata-pro = callPackage ./pragmata-pro.nix { };
  };
in
packages
