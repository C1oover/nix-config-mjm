{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  inherit (lib) mkDefault mkIf mkMerge;
in
{
  imports = [
    "${inputs.catppuccin}/modules/nixos"
    "${inputs.home-manager}/nixos"
    "${inputs.microvm}/nixos-modules/host"

    ../../common/base

    ./attic.nix
    ./netns.nix
    ./networkd.nix
    ./user.nix
  ];

  config = mkMerge [
    {
      microvm.host.enable = mkDefault false;

      nix.channel.enable = true;
      nix.settings.trusted-users = [
        "root"
        config.mjm.username
      ];

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
    }
    (mkIf (!config.mjm.minimal.enable) {
      zramSwap.enable = true;
      system.extraSystemBuilderCmds = ''
        ln -s ${pkgs.nvd-json}/bin/nvd-json $out/bin/nvd-json
      '';
    })
  ];
}
