let
  inputs = import ./npins/patched.nix;
  pkgs = import inputs.nixos { config.allowUnfree = true; };
  devshell = import inputs.devshell { nixpkgs = pkgs; };
in
devshell.mkShell (
  { lib, pkgs, ... }:
  let
    inherit (lib) nameValuePair;
  in
  {
    commands = [
      { package = pkgs.colmena; }
      { package = pkgs.just; }
      { package = pkgs.npins; }
    ];

    devshell.packages = builtins.attrValues {
      inherit (pkgs)
        terraform-ls
        vault-bin
        ;

      inherit (import ./terraform { inherit pkgs; }) opentofu;
    };

    env = [
      (nameValuePair "CONSUL_HTTP_ADDR" "consul.service.consul:8500")
      (nameValuePair "VAULT_ADDR" "http://vault.service.consul:8200")
    ];
  }
)
