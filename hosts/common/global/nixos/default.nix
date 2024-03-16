{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default

    ../home-manager.nix
    ../nix.nix
    ./attic.nix
    ./impermanence.nix
    ./networkd.nix
    ./ssh.nix
    ./ssl.nix

    ../../optional/backup.nix
    ../../optional/consul-agent.nix
    ../../optional/desktop
    ../../optional/dns-server
    ../../optional/garage
    ../../optional/gitlab-runner.nix
    ../../optional/nut.nix
    ../../optional/otel-collector.nix
    ../../optional/postgresql.nix
    ../../optional/server
    ../../optional/tailscale.nix
    ../../optional/vault-server.nix
  ] ++ (builtins.attrValues outputs.nixosModules);

  nix.channel.enable = false;
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
    shell = pkgs.zsh;
    hashedPassword = "$6$JhSUuIask83mtadB$iV5I3SmQE13rVV08RpCN4Ho09VvpmCm6xouZ2o7/1rhR63YFh/WtLAdM1f2P4hgJrxi.ss2zh53xpbSqx/zy9/";
  };

  security.sudo.wheelNeedsPassword = false;

  programs.zsh.enable = true;
}
