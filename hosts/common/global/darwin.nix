{ config, inputs, ... }:

{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    inputs.agenix.darwinModules.default
  ];

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
  };

  time.timeZone = "America/Denver";

  nix.configureBuildUsers = true;
  nix.settings = {
    trusted-users = [ "@admin" ];
    experimental-features = [ "nix-command" "flakes" ];
  };

  nixpkgs.config = {
    allowUnfree = true;
  };

  programs.zsh.enable = true;
  programs.nix-index.enable = true;
  services.nix-daemon.enable = true;

  security.pam.enableSudoTouchIdAuth = true;

  users.users.matt = {
    home = "/Users/matt";
  };

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;

  environment.systemPackages = [ inputs.agenix.packages.${config.nixpkgs.system}.default ];
}
