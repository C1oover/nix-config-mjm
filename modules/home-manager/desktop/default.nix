{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let
  inherit (lib)
    attrValues
    mkDefault
    mkIf
    mkOption
    types
    ;
  cfg = config.cloover.desktop;
in
{
  imports = [
    ./controku.nix
    ./darwin.nix
    ./firefox.nix
    ./games.nix
    ./linux.nix
    ./kdeconfig.nix
  ];

  options.cloover.desktop = {
    enable = mkOption {
      type = types.bool;
      default = osConfig.cloover.desktop.enable or false;
    };
  };

  config = mkIf cfg.enable {
    cloover.git.desktop.enable = mkDefault true;
    cloover.helix.enable = mkDefault true;
    cloover.homelab.enable = mkDefault true;
    cloover.shell.desktop.enable = mkDefault true;
    cloover.terminal.enable = mkDefault true;

    # Many of these aren't really desktop-related necessarily, but they _are_
    # tools I don't really need preinstalled on server machines.
    home.packages = attrValues {
      inherit (pkgs)
        attic-client
        fx
        gh
        httpie
        hydra-check
        nix-output-monitor
        nix-tree
        nvd
        serpl
        skim
        ;
    };
  };
}
