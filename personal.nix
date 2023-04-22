{ config, lib, pkgs, ... }:

let
  vssh = pkgs.writeShellScriptBin "vssh" ''
    ${pkgs.vault}/bin/vault ssh \
      -mode="ca" \
      -role="homelab-client" \
      -mount-point="ssh-client-signer" \
      -public-key-path="${config.home.homeDirectory}/.ssh/yubikey.pub" \
      -valid-principals="ubuntu,matt" \
      -no-exec \
      -field=signed_key \
      "$1" \
      >"${config.home.homeDirectory}/.ssh/yubikey-cert.pub"

    ssh -i "${config.home.homeDirectory}/.ssh/yubikey-cert.pub" "$@"
  '';

  tmssh = pkgs.writeShellScriptBin "tmssh" ''
    ${vssh}/bin/vssh "$@" -t 'tmux -CC new -A -s tmssh'
  '';

  devenv = (import (fetchTarball https://github.com/cachix/devenv/archive/v0.6.2.tar.gz)).default;
in
{
  imports = [
    ./common.nix
  ];

  home.packages = with pkgs; [
    consul
    devenv
    flyctl
    minio-client
    nomad
    tarsnap
    vault

    vssh
    tmssh
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

  programs.ssh = {
    enable = true;
    extraOptionOverrides = {
      IdentityFile = "~/.ssh/yubikey.pub";
    };
    matchBlocks = let
      raspberryPiHosts = ["raspberrypi" "raspberrypi2" "raspberrypi3"];
      raspberryPiMatches = with builtins; listToAttrs (map (hostname: {
        name = hostname;
        value = {
          host = hostname;
          user = "ubuntu";
        };
      }) raspberryPiHosts);
      nasMatch = {
        "nas" = {
          host = "nas";
          identityFile = "~/.ssh/id_ed25519";
        };
      };
    in raspberryPiMatches // nasMatch;
  };
}

