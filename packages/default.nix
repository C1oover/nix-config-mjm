{inputs, ...}: {
  perSystem = {system, ...}: let
    pkgs = import inputs.nixos {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    packages = rec {
      hass-auth-header = pkgs.home-assistant.python.pkgs.callPackage ./hass-auth-header.nix {};
      uwsgi = pkgs.python3Packages.callPackage ./uwsgi.nix {};
      linkding = pkgs.callPackage ./linkding.nix {inherit uwsgi;};
      pragmata-pro = pkgs.callPackage ./pragmata-pro.nix {};
    };
  };
}
