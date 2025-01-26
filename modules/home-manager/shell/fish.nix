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

    catppuccin.fish.enable = true;
  };
}
