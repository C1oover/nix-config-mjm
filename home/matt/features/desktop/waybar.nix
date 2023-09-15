{
  programs.waybar = {
    enable = true;
    settings = {
      main = {
        height = 24;
        layer = "top";
        modules-left = ["sway/workspaces" "sway/mode" "hyprland/workspaces"];
        modules-center = ["sway/window" "hyprland/window"];
        modules-right = ["pulseaudio" "network" "cpu" "memory" "battery" "tray" "clock"];
        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = false;
        };
        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = false;
        };
        "sway/window" = {
          rewrite = {
            "(.*) — Mozilla Firefox" = "󰈹 $1";
            "(.*) - Mozilla Thunderbird" = "󰇯 $1";
            "(.*) - Discord" = "󰙯 $1";
          };
        };
        "hyprland/window" = {
          rewrite = {
            "(.*) — Mozilla Firefox" = "󰈹 $1";
            "(.*) - Mozilla Thunderbird" = "󰇯 $1";
            "(.*) - Discord" = "󰙯 $1";
          };
        };
        clock = {
          format = "{:%I:%M %p}";
        };
        network = {
          format = "{icon}";
          tooltip-format-wifi = "{essid} ({signalStrength}%)\n{ipaddr}";
          format-icons = {
            wifi = ["󰤟" "󰤢" "󰤥" "󰤨"];
            disconnected = "󰖪";
            disabled = "󰖪";
            linked = "󰖪";
          };
        };
        cpu = {
          format = "{usage}% ";
        };
        memory = {
          format = "{}% ";
        };
        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{capacity}% {icon}";
          format-icons = ["" "" "" "" ""];
        };
        pulseaudio = {
          format = "{volume}% {icon}";
          format-bluetooth = "{volume}% {icon}";
          format-muted = "";
          format-icons = {
            headphones = "";
            handsfree = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = ["" ""];
          };
          on-click = "pavucontrol";
        };
        tray = {
          spacing = 10;
        };
      };
    };
    style = ./waybar.css;
  };
}
