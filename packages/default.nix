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
      packages = rec {
        uwsgi = pkgs.python3Packages.callPackage ./uwsgi.nix { };
        linkding = pkgs.callPackage ./linkding.nix { inherit uwsgi; };
        pragmata-pro = pkgs.callPackage ./pragmata-pro.nix { };
      };
    };
}
