{ lib
, pkgs
, inputs
, outputs
, ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default

    ./ssh.nix
    ./ssl.nix
  ];

  nix.settings = {
    experimental-features = [ "flakes" "nix-command" ];
  };

  time.timeZone = lib.mkDefault "Etc/UTC";

  users.users.matt = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
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
    extraSpecialArgs = { inherit inputs outputs; };
  };
}
