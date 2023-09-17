{inputs, ...}: {
  perSystem = {system, ...}: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    lib = pkgs.lib;
  in {
    packages = rec {
      beeper = pkgs.callPackage ./beeper.nix {};
      pragmata-pro = pkgs.callPackage ./pragmata-pro.nix {};

      ssdpy = pkgs.python3Packages.callPackage ./ssdpy.nix {};
      controku = pkgs.python3Packages.callPackage ./controku.nix {inherit ssdpy;};
    };

    apps.update-beeper.program = toString (pkgs.writeShellScript "update-beeper" ''
      ${lib.getExe pkgs.nix} build .#beeper.updateScript && ./result
    '');
  };
}
