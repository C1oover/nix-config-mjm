{ inputs, outputs, ... }:
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    inputs.agenix.darwinModules.default

    ./dock.nix
    ./fonts.nix
    ./homebrew.nix
    ./keyboard.nix
    ../home-manager.nix
    ../nix.nix
  ] ++ (builtins.attrValues outputs.darwinModules);

  nixpkgs.overlays = [ inputs.nixpkgs-firefox-darwin.overlay ];

  nix.configureBuildUsers = true;
  nix.settings.trusted-users = [ "@admin" ];
  services.nix-daemon.enable = true;

  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nix.nixPath = [ "nixpkgs=flake:nixpkgs" ];

  time.timeZone = "America/Denver";

  programs.zsh.enable = true;

  security.pam.enableSudoTouchIdAuth = true;

  users.users.matt = {
    home = "/Users/matt";
  };

  environment.etc."sudoers.d/admin-no-passwd".text = ''
    %admin ALL = (ALL) NOPASSWD: ALL
  '';
}
