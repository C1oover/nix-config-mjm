{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    "${inputs.home-manager}/nix-darwin"

    ../../common/base

    ./keyboard.nix
    ./user.nix
  ];

  nixpkgs.overlays = [ (import "${inputs.nixpkgs-firefox-darwin}/overlay.nix") ];

  nix.settings.trusted-users = [ "@admin" ];

  time.timeZone = "America/Denver";

  environment.darwinConfig = null;
  environment.etc."set-environment".source = config.system.build.setEnvironment;

  environment.shells = [ config.programs.fish.package ];

  security.pam.services.sudo_local.touchIdAuth = true;

  environment.etc."sudoers.d/admin-no-passwd".text = ''
    %admin ALL = (ALL) NOPASSWD: ALL
  '';

  environment.systemPackages = [ pkgs.openssh ];
}
