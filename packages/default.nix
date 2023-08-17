{inputs, ...}: {
  perSystem = {system, ...}: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    lib = pkgs.lib;
  in {
    packages.beeper = pkgs.callPackage ./beeper.nix {};
    packages.pragmata-pro = pkgs.callPackage ./pragmata-pro.nix {};

    apps.update-beeper.program = toString (pkgs.writeShellScript "update-beeper" ''
      ${lib.getExe pkgs.nix} build .#beeper.updateScript && ./result
    '');
  };
}
