{
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}: {
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      inputs.agenix.nixosModules.default

      ../home-manager.nix
      ../nix.nix
      ./attic.nix
      ./ssh.nix
      ./ssl.nix
    ]
    ++ (builtins.attrValues outputs.nixosModules);

  nix.settings.trusted-users = ["root" "matt"];

  zramSwap.enable = true;

  # use nix-index/nix-locate instead
  programs.command-not-found.enable = false;

  time.timeZone = lib.mkDefault "Etc/UTC";

  users.users.matt = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    shell = pkgs.zsh;
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
    nvd
  ];

  programs.zsh.enable = true;
  programs.tmux.enable = true;
}
