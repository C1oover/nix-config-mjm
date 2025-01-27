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
        "1password/tap/1password-cli"
        "alfred"
        "bitwarden"
        "bruno"
        "chrysalis"
        "dash"
        "docker"
        "element"
        "fantastical"
        "submariner"
      ];
    };

    programs.fish.shellInit = mkIf config.homebrew.enable ''
      ${config.homebrew.brewPrefix}/brew shellenv | source
    '';
  };
}
