{ pkgs, config, ... }:
{
  imports = [
    ./global
    ./global/darwin.nix

    ./features/helix
    ./features/taskwarrior
    ./features/work
  ];

  home.dock = {
    enable = true;
    entries = [
      { path = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/"; }
      { path = "${pkgs.firefox-bin}/Applications/Firefox.app/"; }
      { path = "/Applications/Beeper.app/"; }
      { path = "/System/Applications/Mail.app/"; }
      { path = "${pkgs.zoom-us}/Applications/zoom.us.app/"; }
      { path = "${pkgs.slack}/Applications/Slack.app/"; }
      { path = "/Applications/Fantastical.app/"; }
      { path = "/Applications/1Password.app/"; }
      { path = "/Applications/Slab.app/"; }
      { path = "${pkgs.kitty}/Applications/kitty.app/"; }
      { path = "/Applications/Dash.app/"; }
      { path = "/Applications/Postico 2.app/"; }
      { path = "${pkgs.discord}/Applications/Discord.app/"; }
      {
        path = "${config.home.homeDirectory}/Downloads/";
        section = "others";
        options = "--sort dateadded --view grid --display folder";
      }
    ];
  };
}
