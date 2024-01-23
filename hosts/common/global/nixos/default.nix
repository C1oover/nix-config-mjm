{
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
    ./networkd.nix
    ./ssh.nix
    ./ssl.nix
  ] ++ (builtins.attrValues outputs.nixosModules);

  nix.settings.trusted-users = [
    "root"
    "matt"
  ];

  zramSwap.enable = true;

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

  environment.systemPackages = with pkgs; [
    git
    nvd
  ];

  programs.zsh.enable = true;
  programs.tmux.enable = true;
}
