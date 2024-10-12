{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    "${inputs.home-manager}/nixos"
    "${inputs.agenix}/modules/age.nix"
    "${inputs.catppuccin}/modules/nixos"

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

  # hash mismatch in the go modules for vault rn
  nixpkgs.overlays = [
    (final: prev: { vault = prev.vault-bin; })
  ];

  nix.channel.enable = true;
  nix.settings.trusted-users = [
    "root"
    "matt"
  ];

  zramSwap.enable = true;
  boot.initrd.systemd.enable = !config.boot.isContainer;
  mjm.userborn.enable = !config.boot.isContainer;

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

  system.extraSystemBuilderCmds =
    let
      nvd-json = import ../../../../apps/nvd-json { inherit pkgs; };
    in
    ''
      ln -s ${nvd-json}/bin/nvd-json $out/bin/nvd-json
    '';
}
