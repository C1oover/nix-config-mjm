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

      ./auto-upgrade.nix
      ./ssh.nix
      ./ssl.nix
      ./node-exporter.nix
      ./promtail.nix
    ]
    ++ (builtins.attrValues outputs.nixosModules);

  nix.settings = {
    experimental-features = ["flakes" "nix-command"];
  };
  nix.registry = {
    nixpkgs.flake = inputs.nixpkgs;
    home-manager.flake = inputs.home-manager;
  };

  time.timeZone = lib.mkDefault "Etc/UTC";

  users.users.matt = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    shell = pkgs.zsh;
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    neovim
    git
    python310 # for using ansible to update the system
  ];

  programs.zsh.enable = true;
  programs.tmux.enable = true;

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = {inherit inputs outputs;};
    backupFileExtension = "bak";
  };
}
