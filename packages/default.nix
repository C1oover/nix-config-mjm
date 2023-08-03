{inputs, ...}: {
  perSystem = {system, ...}: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    packages.beeper = pkgs.callPackage ./beeper.nix {};
    packages.pragmata-pro = pkgs.callPackage ./pragmata-pro.nix {};
  };
}
