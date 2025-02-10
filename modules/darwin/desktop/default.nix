{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.desktop;
in
{
  imports = [ ../../common/desktop.nix ];

  config = mkIf cfg.enable {
    homebrew = {
      enable = true;
      casks = [
        "1password"
        "alfred"
        "bitwarden"
        "bruno"
        "chrysalis"
        "dash"
        "element"
        "fantastical"
        "soundsource"
        "stats"
        "submariner"
      ];
    };

    programs.fish.shellInit = mkIf config.homebrew.enable ''
      ${config.homebrew.brewPrefix}/brew shellenv | source
    '';
  };
}
