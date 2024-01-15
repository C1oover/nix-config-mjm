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

      ./dock.nix
      ./fonts.nix
      ./homebrew.nix
      ./keyboard.nix
      ../home-manager.nix
      ../nix.nix
    ]
    ++ (builtins.attrValues outputs.darwinModules);

  nixpkgs.overlays = [
    inputs.nixpkgs-firefox-darwin.overlay
  ];

  nix.configureBuildUsers = true;
  nix.settings.trusted-users = ["@admin"];
  services.nix-daemon.enable = true;

  time.timeZone = "America/Denver";

  programs.zsh.enable = true;

  security.pam.enableSudoTouchIdAuth = true;

  users.users.matt = {
    home = "/Users/matt";
  };

  environment.systemPackages = with pkgs; [
    nvd
    inputs.agenix.packages.${config.nixpkgs.system}.default
  ];

  environment.etc."sudoers.d/admin-no-passwd".text = ''
    %admin ALL = (ALL) NOPASSWD: ALL
  '';
}
