let
  inputs = import ./npins;
  pkgs = import inputs.nixos {
    config.allowUnfree = true;
    overlays = [ (import ./overlay.nix) ];
  };
  devshell = import inputs.devshell { nixpkgs = pkgs; };
in
devshell.mkShell (
  { lib, pkgs, ... }:
  let
    inherit (lib) attrValues nameValuePair;
  in
  {
    commands = [
      { package = pkgs.just; }
      { package = pkgs.npins; }
      {
        name = "dippy";
        command = ''nix run -f . dippy -- "$@"'';
      }
    ];

    devshell.packages = attrValues {
      inherit (pkgs)
        nixfmt-rfc-style
        vault-bin
        ;
    };

    env = [
      (nameValuePair "CONSUL_HTTP_ADDR" "consul.service.consul:8500")
      (nameValuePair "VAULT_ADDR" "https://vault.midna.dev")
    ];
  }
)
