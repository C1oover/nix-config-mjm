{ pkgs, inputs, ... }:
{
  imports = [
    # disable for now since using the plasma5 stuff for this seems to mess with plasma6 some
    #    ./rc.nix
  ];

  home.packages = builtins.attrValues {
    inherit (pkgs)
      bitwarden
      imv
      wl-clipboard
      xdg-utils
      zeal
      ;
    inherit (pkgs.callPackages ./scripts.nix { }) night-mode;
    inherit (inputs.kde2nix.packages.${pkgs.system})
      kbreakout
      kmahjongg
      kmines
      kpat
      palapeli
      ;
    inherit (inputs.plasma-manager.packages.${pkgs.system}) rc2nix;
  };

  programs.mpv.enable = true;

  services.kdeconnect.enable = true;
}
