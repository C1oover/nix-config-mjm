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
      { pkgs, lib, ... }:
      let
        # TODO patch upstream
        npins = pkgs.npins.overrideAttrs (oldAttrs: {
          buildInputs =
            oldAttrs.buildInputs
            ++ lib.optional pkgs.stdenv.isDarwin pkgs.darwin.apple_sdk.frameworks.SystemConfiguration;
        });
      in
      {
        imports = [
          ./hosts/devenv.nix
          ./terraform/devenv.nix
        ];

        packages = [
          pkgs.just
          npins
        ];

        dotenv.disableHint = true;
      }
    )
  ];
}
