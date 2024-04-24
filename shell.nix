let
  inputs = import ./npins;
  pkgs = import inputs.nixos { config.allowUnfree = true; };
  devenv = import inputs.devenv;
in
devenv.lib.mkShell {
  inherit pkgs;
  inputs = {
    inherit devenv;
    nixpkgs = {
      lib = import "${inputs.nixos}/lib";
    };
    self = ./.;
  };
  modules = [
    (
      { pkgs, ... }:
      {
        imports = [
          ./hosts/devenv.nix
          ./terraform/devenv.nix
        ];

        packages = [
          pkgs.just
          pkgs.npins
        ];

        dotenv.disableHint = true;
      }
    )
  ];
}
