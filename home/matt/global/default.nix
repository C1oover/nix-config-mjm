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

      ../features/git
      ../features/shell
    ]
    ++ (builtins.attrValues outputs.homeManagerModules);

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = lib.mkDefault "22.11"; # Please read the comment before changing.

  home.packages = with pkgs; [
    gh
    httpie
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
      then "nixos-rebuild build && nvd diff /run/current-system result"
      else "darwin-rebuild build --flake . && nvd diff /run/current-system result";
    switch =
      if pkgs.stdenv.isLinux
      then "nixos-rebuild switch --use-remote-sudo"
      else "darwin-rebuild switch --flake .";
  };

  news.display = "silent";

  programs.home-manager.enable = true;

  programs.jq.enable = true;
}
