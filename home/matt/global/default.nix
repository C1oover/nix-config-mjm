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

  home.packages = with pkgs; let
    interpreter = lib.getExe bash;
    variant =
      if stdenv.isLinux
      then "linux"
      else "darwin";
  in
    [
      btop
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

      (resholve.writeScriptBin ",rb" {
        inherit interpreter;
        inputs = [nix-output-monitor nvd] ++ lib.optional (variant == "linux") nettools;
        fake.external = ["scutil"];
        execer = [
          "cannot:${nix-output-monitor}/bin/nom"
          "cannot:${nvd}/bin/nvd"
        ];
      } (builtins.readFile ./rebuild.${variant}.sh))

      (resholve.writeScriptBin ",sw" {
        inherit interpreter;
        inputs =
          [
            nix
            coreutils
          ]
          ++ lib.optional (variant == "linux") systemd;
        fake.external = ["sudo"];
        keep."$PWD" = true;
      } (builtins.readFile ./switch.${variant}.sh))

      inputs.home-manager.packages.${pkgs.system}.home-manager
      inputs.agenix.packages.${pkgs.system}.default
    ]
    ++ lib.optional pkgs.stdenv.isLinux pkgs.attic;

  home.shellAliases = {
    td = "cd $(mktemp -d)";
  };

  news.display = "silent";

  programs.home-manager.enable = true;

  programs.jq.enable = true;

  colorScheme = inputs.nix-colors.colorSchemes.catppuccin-mocha;
}
