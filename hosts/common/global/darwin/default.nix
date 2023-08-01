{
  pkgs,
  config,
  inputs,
  outputs,
  ...
}: {
  imports =
    [
      inputs.home-manager.darwinModules.home-manager
      inputs.agenix.darwinModules.default
      inputs.nixvim.nixDarwinModules.nixvim

      ./dock.nix
      ./homebrew.nix
      ./keyboard.nix
      ../nix.nix
      ../nixvim
    ]
    ++ (builtins.attrValues outputs.darwinModules);

  nixpkgs.overlays = [
    inputs.nixpkgs-firefox-darwin.overlay
  ];

  nix.configureBuildUsers = true;
  nix.settings.trusted-users = ["@admin"];
  services.nix-daemon.enable = true;

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = {inherit inputs outputs;};
    backupFileExtension = "bak";
  };

  time.timeZone = "America/Denver";

  programs.zsh.enable = true;
  programs.nix-index.enable = true;

  security.pam.enableSudoTouchIdAuth = true;

  users.users.matt = {
    home = "/Users/matt";
  };

  environment.systemPackages = with pkgs; [
    nvd
    inputs.agenix.packages.${config.nixpkgs.system}.default
  ];
}
