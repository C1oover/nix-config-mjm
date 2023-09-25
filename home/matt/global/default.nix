{
  pkgs,
  lib,
  outputs,
  inputs,
  ...
}: {
  imports =
    [
      inputs.agenix.homeManagerModules.default
      inputs.nix-colors.homeManagerModules.default

      ../features/git
      ../features/helix
      ../features/shell
      ../features/xdg
    ]
    ++ (builtins.attrValues outputs.homeManagerModules);

  home.stateVersion = lib.mkDefault "22.11";

  home.packages = with pkgs; [
    fx
    gh
    httpie
    nix-output-monitor
    nix-tree
    pstree
    ripgrep
    tree
    unzip
    wget

    inputs.home-manager.packages.${pkgs.system}.home-manager
    inputs.agenix.packages.${pkgs.system}.default
  ];

  home.shellAliases = {
    td = "cd $(mktemp -d)";
    hm = "home-manager";
    rebuild =
      if pkgs.stdenv.isLinux
      then "${pkgs.nix-output-monitor}/bin/nom build .#nixosConfigurations.$(hostname).config.system.build.toplevel && ${pkgs.nvd}/bin/nvd diff /run/current-system result"
      else "${pkgs.nix-output-monitor}/bin/nom build .#darwinConfigurations.$(hostname).config.system.build.toplevel && ${pkgs.nvd}/bin/nvd diff /run/current-system result";
    switch =
      if pkgs.stdenv.isLinux
      then "nixos-rebuild switch --use-remote-sudo"
      else "darwin-rebuild switch --flake .";
  };

  news.display = "silent";

  programs.home-manager.enable = true;

  programs.jq.enable = true;

  colorScheme = inputs.nix-colors.colorSchemes.catppuccin-mocha;
}
