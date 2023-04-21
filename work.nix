{ pkgs, ... }:

{
  imports = [
    ./common.nix
  ];

  home.packages = with pkgs; [
    gh
    google-cloud-sdk
    teleport
    zoom-us
  ];

  programs.git.userEmail = "matt@slab.com";
}
