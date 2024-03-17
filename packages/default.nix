{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixos {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      packages = {
        linkding = pkgs.callPackage ./linkding.nix { };
        mautrix-slack = pkgs.callPackage ./mautrix-slack.nix { };
        pragmata-pro = pkgs.callPackage ./pragmata-pro.nix { };
      };
    };
}
