{ lib, ... }:
let
  inherit (lib) mkEnableOption;
in
{
  imports = [
    ./home-manager.nix
    ./ipv6.nix
    ./nix.nix
    ./user.nix
  ];

  options.mjm.minimal = {
    enable = mkEnableOption "minimal settings for microvms";
  };

  config = {
    programs.fish.enable = true;
  };
}
