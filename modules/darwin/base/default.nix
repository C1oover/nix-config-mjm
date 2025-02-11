{ inputs, config, ... }:
{
  imports = [
    "${inputs.home-manager}/nix-darwin"

    ../../common/base

    ./dock.nix
    ./keyboard.nix
    ./user.nix
  ];

  nixpkgs.overlays = [ (import "${inputs.nixpkgs-firefox-darwin}/overlay.nix") ];

  nix.settings.trusted-users = [ "@admin" ];

  time.timeZone = "America/Denver";

  environment.etc."set-environment".source = config.system.build.setEnvironment;

  environment.shells = [ config.programs.fish.package ];

  security.pam.enableSudoTouchIdAuth = true;

  environment.etc."sudoers.d/admin-no-passwd".text = ''
    %admin ALL = (ALL) NOPASSWD: ALL
  '';
}
