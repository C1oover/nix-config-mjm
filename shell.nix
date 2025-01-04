let
  inputs = import ./npins/patched.nix;
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
    ];

    devshell.packages = attrValues {
      inherit (pkgs)
        opentofu
        terraform-ls
        vault-bin
        ;
    };

    env = [
      (nameValuePair "CONSUL_HTTP_ADDR" "consul.service.consul:8500")
      (nameValuePair "VAULT_ADDR" "http://vault.service.consul:8200")
    ];
  }
)
