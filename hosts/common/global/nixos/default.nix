{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  lanzaboote = import inputs.lanzaboote;
in
{
  imports = [
    "${inputs.home-manager}/nixos"
    "${inputs.catppuccin}/modules/nixos"
    lanzaboote.nixosModules.lanzaboote

    ../home-manager.nix
    ../nix.nix
    ./attic.nix
    ./backup.nix
    ./desktop
    ./impermanence.nix
    ./networkd.nix
    ./server
    ./ssh.nix
    ./wireless.nix

    ../../../../services
  ] ++ (builtins.attrValues (import ../../../../modules/nixos));

  nix.channel.enable = true;
  nix.settings.trusted-users = [
    "root"
    "matt"
  ];

  zramSwap.enable = true;
  boot.initrd.systemd.enable = true;

  # use nix-index/nix-locate instead
  programs.command-not-found.enable = false;

  time.timeZone = lib.mkDefault "Etc/UTC";

  users.mutableUsers = false;
  users.users.matt = {
    isNormalUser = true;
    description = "MJ";
    extraGroups = [ "wheel" ];
    shell = config.programs.nushell.wrappedPackage;
    hashedPassword = "$y$j9T$tM/RKSjlb5ljgtpGT/Y8N1$3oXxWQh/q.KKCcJKoyVeIUVqjjt76EWX.uNEJRASt04";
  };

  security.sudo.wheelNeedsPassword = false;

  programs.nushell.enable = true;
  programs.zsh.enable = true;

  catppuccin.flavor = "macchiato";

  environment.systemPackages = [
    pkgs.nvd
    pkgs.kitty.terminfo
  ];

  system.extraSystemBuilderCmds = ''
    ln -s ${pkgs.nvd-json}/bin/nvd-json $out/bin/nvd-json
  '';
}
