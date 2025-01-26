{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../../common/base
    ./attic.nix
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

  time.timeZone = lib.mkDefault "Etc/UTC";

  users.mutableUsers = false;
  security.sudo.wheelNeedsPassword = false;

  programs.nushell.enable = true;
  programs.zsh.enable = true;
  programs.fish.enable = true;

  catppuccin.flavor = "macchiato";

  environment.systemPackages = [
    pkgs.nvd
    pkgs.ghostty.terminfo
    pkgs.kitty.terminfo
  ];

  system.extraSystemBuilderCmds = ''
    ln -s ${pkgs.nvd-json}/bin/nvd-json $out/bin/nvd-json
  '';
}
