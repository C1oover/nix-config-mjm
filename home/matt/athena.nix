{ pkgs, config, ... }:
let
  tomlFormat = pkgs.formats.toml { };
in
{
  imports = [
    ./global
    ./global/darwin.nix

    ./features/helix
    ./features/taskwarrior
    ./features/work
  ];

  programs.kitty.font.size = 13;

  home.dock = {
    enable = true;
    entries = [
      { path = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/"; }
      { path = "${config.programs.firefox.package}/Applications/Firefox.app/"; }
      { path = "/Applications/Element.app/"; }
      { path = "/System/Applications/Messages.app/"; }
      { path = "/System/Applications/Mail.app/"; }
      { path = "${pkgs.zoom-us}/Applications/zoom.us.app/"; }
      { path = "${pkgs.slack}/Applications/Slack.app/"; }
      { path = "/Applications/Fantastical.app/"; }
      { path = "/Applications/1Password.app/"; }
      { path = "/Applications/Bitwarden.app/"; }
      { path = "/Applications/Slab.app/"; }
      { path = "${config.programs.kitty.package}/Applications/kitty.app/"; }
      { path = "/Applications/Dash.app/"; }
      { path = "/Applications/Postico 2.app/"; }
      { path = "/Applications/Teleport Connect.app/"; }
      { path = "${pkgs.discord}/Applications/Discord.app/"; }
      {
        path = "${config.home.homeDirectory}/Downloads/";
        section = "others";
        options = "--sort dateadded --view grid --display folder";
      }
    ];
  };

  xdg.configFile."aerospace/aerospace.toml".source = tomlFormat.generate "aerospace.toml" {
    start-at-login = true;
    mode.main.binding = {
      alt-shift-slash = "layout tiles";
      alt-shift-quote = "layout accordion";
      alt-shift-t = "layout horizontal vertical";

      alt-h = "focus left";
      alt-j = "focus down";
      alt-k = "focus up";
      alt-l = "focus right";

      alt-shift-h = "move left";
      alt-shift-j = "move down";
      alt-shift-k = "move up";
      alt-shift-l = "move right";

      alt-ctrl-h = "join-with left";
      alt-ctrl-j = "join-with down";
      alt-ctrl-k = "join-with up";
      alt-ctrl-l = "join-with right";

      alt-1 = "workspace 1";
      alt-2 = "workspace 2";
      alt-3 = "workspace 3";
      alt-4 = "workspace 4";
      alt-5 = "workspace 5";
      alt-6 = "workspace 6";
      alt-7 = "workspace 7";
      alt-8 = "workspace 8";
      alt-9 = "workspace 9";

      alt-shift-1 = "move-node-to-workspace 1";
      alt-shift-2 = "move-node-to-workspace 2";
      alt-shift-3 = "move-node-to-workspace 3";
      alt-shift-4 = "move-node-to-workspace 4";
      alt-shift-5 = "move-node-to-workspace 5";
      alt-shift-6 = "move-node-to-workspace 6";
      alt-shift-7 = "move-node-to-workspace 7";
      alt-shift-8 = "move-node-to-workspace 8";
      alt-shift-9 = "move-node-to-workspace 9";

      alt-tab = "workspace-back-and-forth";
      alt-shift-tab = "move-workspace-to-monitor --wrap-around next";

      alt-shift-c = "reload-config";

      alt-shift-f = "layout floating tiling";
    };
    workspace-to-monitor-force-assignment = {
      "1" = "main";
      "2" = [
        "secondary"
        "main"
      ];
      "3" = "main";
      "4" = "main";
    };
    on-window-detected = [
      {
        "if".app-id = "us.zoom.xos";
        run = "move-node-to-workspace 4";
      }
    ];
  };
}
