{ inputs, ... }:
{
  imports = [
    ../../common/base

    ./dock.nix
    ./keyboard.nix
    ./user.nix
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
