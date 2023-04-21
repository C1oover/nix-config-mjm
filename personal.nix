{ pkgs, ... }:

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
}

