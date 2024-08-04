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
  nixpkgs.overlays = [ (final: prev: { vault = prev.vault-bin; }) ];

  nix.channel.enable = true;
  nix.settings.trusted-users = [
    "root"
    "matt"
  ];

  zramSwap.enable = true;
  boot.initrd.systemd.enable = !config.boot.isContainer;

  # use nix-index/nix-locate instead
  programs.command-not-found.enable = false;

  time.timeZone = lib.mkDefault "Etc/UTC";

  users.mutableUsers = false;
  users.users.matt = {
    isNormalUser = true;
    description = "MJ";
    extraGroups = [ "wheel" ];
    shell = config.programs.nushell.wrappedPackage;
    hashedPassword = "$6$JhSUuIask83mtadB$iV5I3SmQE13rVV08RpCN4Ho09VvpmCm6xouZ2o7/1rhR63YFh/WtLAdM1f2P4hgJrxi.ss2zh53xpbSqx/zy9/";
  };

  security.sudo.wheelNeedsPassword = false;

  programs.nushell.enable = true;
  programs.zsh.enable = true;

  catppuccin.flavor = "macchiato";

  environment.systemPackages = [
    pkgs.nvd
    (pkgs.writers.writeNuBin "system-upgrade-check" ''
      def get-kernel-version [system_path: path] {
        let kernel_path = $system_path | path join kernel
        if ($kernel_path | path exists) {
          $kernel_path | path expand | path dirname | path basename | split row - | get 2
        } else {
          '<none>'
        }
      }

      def get-systemd-version [system_path: path] {
        let systemd_path = $system_path | path join systemd | path expand
        $systemd_path | path basename | split row - | get 2
      }

      def main [
        system_path: path
        --ignore-errors (-n)
      ] {
        nvd diff /run/current-system $system_path

        let old_kernel_version = get-kernel-version /run/booted-system
        let new_kernel_version = get-kernel-version $system_path
        let kernel_changed = $old_kernel_version != $new_kernel_version;
        if $kernel_changed {
          print $'Kernel versions differ: ($old_kernel_version) -> ($new_kernel_version)'
        }

        let old_systemd_version = get-systemd-version /run/booted-system
        let new_systemd_version = get-systemd-version $system_path
        let systemd_changed = $old_systemd_version != $new_systemd_version
        if $systemd_changed {
          print $'systemd versions differ: ($old_systemd_version) -> ($new_systemd_version)'
        }

        if $kernel_changed or $systemd_changed {
          print 'Reboot needed.'
          if not $ignore_errors { exit 1 }
        }
      }
    '')
  ];
}
