{ inputs, ... }:
let
  pkgsForPatching = import inputs.nixpkgs { };
  inherit (pkgsForPatching) applyPatches fetchpatch;

  home-manager-patched = applyPatches {
    name = "home-manager-patched";
    src = inputs.home-manager;
    patches = [
      (fetchpatch {
        # fix generated profiles.ini on darwin
        url = "https://patch-diff.githubusercontent.com/raw/nix-community/home-manager/pull/5723.diff";
        hash = "sha256-eD2gKScImfDyF9dTQ6rqK7lf/xbucHSxthRoSBre2dY=";
      })
    ];
  };
in
{
  imports = [
    "${home-manager-patched}/nix-darwin"
    "${inputs.agenix}/modules/age.nix"

    ../../../../modules/nixos/nushell.nix

    ./dock.nix
    ./fonts.nix
    ./homebrew.nix
    ./keyboard.nix
    ../home-manager.nix
    ../nix.nix
  ];

  nixpkgs.overlays = [ (import "${inputs.nixpkgs-firefox-darwin}/overlay.nix") ];

  nix.configureBuildUsers = true;
  nix.settings.trusted-users = [ "@admin" ];
  services.nix-daemon.enable = true;

  time.timeZone = "America/Denver";

  programs.nushell.enable = true;
  programs.zsh.enable = true;

  security.pam.enableSudoTouchIdAuth = true;

  users.users.matt = {
    home = "/Users/matt";
  };

  environment.etc."sudoers.d/admin-no-passwd".text = ''
    %admin ALL = (ALL) NOPASSWD: ALL
  '';
}
