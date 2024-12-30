{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.desktop;
in
{
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
  };
}
