{ config, lib, pkgs, ... }:

{
  imports = [
    ./common.nix
  ];

  home.packages = with pkgs; [
    consul
    minio-client
    nomad
    tarsnap
    vault
  ];

  home.sessionVariables = {
    NOMAD_ADDR = "https://nomad.service.consul:4646";
    NOMAD_CACERT = "${config.home.homeDirectory}/.config/nomad/ca.crt";
    NOMAD_CLIENT_CERT = "${config.home.homeDirectory}/.config/nomad/cli.crt";
    NOMAD_CLIENT_KEY = "${config.home.homeDirectory}/.config/nomad/cli.key";
    NOMAD_TOKEN = lib.strings.removeSuffix "\n" (builtins.readFile secrets/nomad-token);

    CONSUL_HTTP_ADDR = "10.0.0.2:8500";

    VAULT_ADDR = "http://vault.service.consul:8200";
  };
}

