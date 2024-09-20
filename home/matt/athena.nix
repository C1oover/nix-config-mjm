{ pkgs, config, ... }:
let
  tomlFormat = pkgs.formats.toml { };
in
{
  imports = [
    ./global
    ./global/darwin.nix

    ./features/taskwarrior
    ./features/work
  ];

  mjm.helix.enable = true;

  programs.kitty.font.size = 13;

  home.dock.entries = [
    {
      app = "Firefox";
      package = config.programs.firefox.package;
    }
    { app = "Element"; }
    { app = "Signal"; }
    { app = "Mail"; }
    {
      app = "zoom.us";
      package = pkgs.zoom-us;
    }
    {
      app = "Slack";
      package = pkgs.slack;
    }
    { app = "Fantastical"; }
    { app = "1Password"; }
    { app = "Bitwarden"; }
    { app = "Slab"; }
    {
      app = "kitty";
      package = config.programs.kitty.package;
    }
    { app = "Dash"; }
    { app = "Postico 2"; }
    { app = "Teleport Connect"; }
    { app = "Bruno"; }
    {
      path = "${config.home.homeDirectory}/Downloads/";
      section = "others";
      options = "--sort dateadded --view grid --display folder";
    }
  ];

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

  home.packages = [
    (pkgs.writers.writeNuBin ",aero" ''
      let $kitty = 'net.kovidgoyal.kitty'
      let $slack = 'com.tinyspeck.slackmacgap'

      def get-window-id-for-app [app_id: string] {
        aerospace list-windows --monitor all --app-bundle-id $app_id --format %{window-id} | split row "\n" | get 0
      }

      def set-app-layout [app_id: string, layout: string] {
        aerospace focus --window-id (get-window-id-for-app $app_id)
        aerospace layout $layout
      }

      def "main portable" [] {
        set-app-layout $kitty h_accordion
        set-app-layout $slack v_accordion
      }

      def "main docked" [] {
        set-app-layout $kitty h_tiles
        set-app-layout $slack v_tiles
      }

      def main [] {}
    '')
  ];
}
