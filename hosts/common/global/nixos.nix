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

      ./ssh.nix
      ./ssl.nix
      ./nixvim
    ]
    ++ (builtins.attrValues outputs.nixosModules);

  nix.settings = {
    experimental-features = ["flakes" "nix-command"];
    trusted-users = ["root" "matt"];
  };
  nix.registry = {
    nixpkgs.flake = inputs.nixpkgs;
    home-manager.flake = inputs.home-manager;
  };
  nixpkgs.config = {
    # the vscode-langservers-extracted package pulls them out of VSCode,
    # which is unfree
    allowUnfree = true;
  };
  nixpkgs.overlays = [
    inputs.nur.overlay
  ];

  time.timeZone = lib.mkDefault "Etc/UTC";

  users.users.matt = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    shell = pkgs.zsh;
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
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
