{
  lib,
  config,
  osConfig,
  ...
}:
let
  inherit (lib)
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
    mjm.helix.enable = mkDefault true;
    mjm.terminal.enable = mkDefault true;
  };
}
