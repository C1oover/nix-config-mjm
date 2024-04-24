{ pkgs, ... }:
let
  inherit (import ./. { inherit pkgs; }) opentofu;
in
{
  env = {
    CONSUL_HTTP_ADDR = "consul.service.consul:8500";
    VAULT_ADDR = "http://vault.service.consul:8200";
  };

  packages = [
    pkgs.vault-bin
    pkgs.openssh
  ];

  languages.terraform = {
    enable = true;
    package = opentofu;
  };
}
