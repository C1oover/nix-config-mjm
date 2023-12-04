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
      ../features/shell
      ../features/xdg
    ]
    ++ (builtins.attrValues outputs.homeManagerModules);

  home.stateVersion = lib.mkDefault "22.11";

  home.packages = with pkgs;
    [
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

      (pkgs.writeShellApplication {
        name = ",rb";
        runtimeInputs = with pkgs; [nix nix-output-monitor nvd];
        text =
          if pkgs.stdenv.isLinux
          then ''
            echo TODO
          ''
          else ''
            nom build ".#darwinConfigurations.$(scutil --get LocalHostName).system"
            nvd diff /run/current-system ./result
          '';
      })

      (pkgs.writeShellApplication {
        name = ",sw";
        runtimeInputs = with pkgs; [nix];
        text = let
          profile = "/nix/var/nix/profiles/system";
        in
          if pkgs.stdenv.isLinux
          then ''
            echo TODO
          ''
          else ''
            sudo -H --preserve-env=PATH env nix-env -p "${profile}" --set "$(readlink -f result)"
            ./result/activate-user
            sudo -H --preserve-env=PATH ./result/activate
          '';
      })

      inputs.home-manager.packages.${pkgs.system}.home-manager
      inputs.agenix.packages.${pkgs.system}.default
    ]
    ++ lib.optional pkgs.stdenv.isLinux pkgs.attic;

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
