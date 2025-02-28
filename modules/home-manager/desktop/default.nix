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
  cfg = config.mjm.desktop;
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

  options.mjm.desktop = {
    enable = mkOption {
      type = types.bool;
      default = osConfig.mjm.desktop.enable or false;
    };
  };

  config = mkIf cfg.enable {
    mjm.git.desktop.enable = mkDefault true;
    mjm.helix.enable = mkDefault true;
    mjm.homelab.enable = mkDefault true;
    mjm.shell.desktop.enable = mkDefault true;
    mjm.terminal.enable = mkDefault true;

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
