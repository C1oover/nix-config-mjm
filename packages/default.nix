{inputs, ...}: {
  perSystem = {system, ...}: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    packages = {
      pragmata-pro = pkgs.callPackage ./pragmata-pro.nix {};
    };
  };
}
