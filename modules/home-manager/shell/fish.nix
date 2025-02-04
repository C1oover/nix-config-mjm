{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.shell;
in
{
  config = mkIf cfg.enable {
    programs.fish = {
      enable = true;
    };

    programs.carapace.enableFishIntegration = false;

    catppuccin.fish.enable = true;
  };
}
