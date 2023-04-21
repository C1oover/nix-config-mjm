{ pkgs, ... }:

{
  imports = [
    ./common.nix
  ];

  home.packages = with pkgs; [
    google-cloud-sdk
    teleport
  ];

  programs.git.userEmail = "matt@slab.com";
}
