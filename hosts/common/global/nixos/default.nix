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
      inputs.nixvim.nixosModules.nixvim

      ../home-manager.nix
      ../nix.nix
      ../nixvim
      ./ssh.nix
      ./ssl.nix
    ]
    ++ (builtins.attrValues outputs.nixosModules);

  nix.settings.trusted-users = ["root" "matt"];

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
