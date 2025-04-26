{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    "${inputs.catppuccin}/modules/nixos"
    "${inputs.home-manager}/nixos"

    ../../common/base

    ./attic.nix
    ./netns.nix
    ./networkd.nix
    ./user.nix
  ];

  nix.channel.enable = true;
  nix.settings.trusted-users = [
    "root"
    config.mjm.username
  ];

  zramSwap.enable = true;
  boot.initrd.systemd.enable = true;

  # use nix-index/nix-locate instead
  programs.command-not-found.enable = false;

  documentation.enable = lib.mkDefault false;
  documentation.man.generateCaches = lib.mkOverride 900 false;

  time.timeZone = lib.mkDefault "Etc/UTC";

  users.mutableUsers = false;
  security.sudo.wheelNeedsPassword = false;

  catppuccin.flavor = "macchiato";

  environment.systemPackages = [
    pkgs.ghostty.terminfo
  ];

  boot.specialFileSystems."/run".options = [ "noswap" ];

  system.extraSystemBuilderCmds = ''
    ln -s ${pkgs.nvd-json}/bin/nvd-json $out/bin/nvd-json
  '';
}
