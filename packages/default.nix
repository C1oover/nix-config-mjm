{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixos {
        inherit system;
        config.allowUnfree = true;
      };
      callPackage = pkgs.lib.callPackageWith (pkgs // packages);
      packages = {
        linkding = callPackage ./linkding.nix { };
        mautrix-slack = callPackage ./mautrix-slack.nix { };
        pragmata-pro = callPackage ./pragmata-pro.nix { };
      };
    in
    {
      inherit packages;
    };
}
