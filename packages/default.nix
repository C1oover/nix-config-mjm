{inputs, ...}: {
  perSystem = {system, ...}: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    packages = {
      pragmata-pro = pkgs.callPackage ./pragmata-pro.nix {};
      hass-auth-header = pkgs.home-assistant.python.pkgs.callPackage ./hass-auth-header.nix {};
    };
  };
}
