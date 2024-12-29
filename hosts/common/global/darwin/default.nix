{ inputs, localModulesPath, ... }:
{
  imports = [
    "${inputs.home-manager}/nix-darwin"
    "${localModulesPath}/darwin"
    ../../../../services/darwin.nix

    ./dock.nix
    ./fonts.nix
    ./homebrew.nix
    ./keyboard.nix
  ];

  nixpkgs.overlays = [ (import "${inputs.nixpkgs-firefox-darwin}/overlay.nix") ];

  nix.configureBuildUsers = true;
  nix.settings.trusted-users = [ "@admin" ];
  services.nix-daemon.enable = true;

  time.timeZone = "America/Denver";

  programs.nushell.enable = true;
  programs.zsh.enable = true;

  security.pam.enableSudoTouchIdAuth = true;

  environment.etc."sudoers.d/admin-no-passwd".text = ''
    %admin ALL = (ALL) NOPASSWD: ALL
  '';
}
