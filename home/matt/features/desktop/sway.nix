{
  pkgs,
  lib,
  inputs,
  config,
  ...
}: {
  home.packages = with pkgs; [
    swaybg
  ];

  wayland.windowManager.sway = {
    enable = true;
    package = null;

    extraConfigEarly = ''
      include ${inputs.catppuccin-i3}/themes/catppuccin-mocha
    '';

    config = let
      mod = "Mod4";
      terminal = "${pkgs.kitty}/bin/kitty";
      menu = ''${pkgs.bemenu}/bin/bemenu-run -i -l 20 --fb "#1e1e2e" --ff "#94e2d5" --nb "#1e1e2e" --nf "#f5e0dc" --tb "#1e1e2e" --hb "#1e1e2e" --tf "#cba6f7" --hf "#89b4fa" --nf "#f5e0dc" --af "#f5e0dc" --ab "#1e1e2e"'';
    in {
      inherit terminal menu;
      modifier = mod;

      keybindings = lib.mkOptionDefault {
        "XF86MonBrightnessDown" = "exec light -U 5";
        "XF86MonBrightnessUp" = "exec light -A 5";
        "XF86AudioRaiseVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +4%";
        "XF86AudioLowerVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -4%";
        "XF86AudioMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
      };

      input."type:keyboard" = {
        xkb_options = "caps:ctrl_modifier";
      };

      input."type:touchpad" = {
        click_method = "clickfinger";
        middle_emulation = "disabled";
        natural_scroll = "enabled";
      };

      bars = [
        {
          command = "${pkgs.waybar}/bin/waybar";
        }
      ];

      assigns = {
        "1" = [{app_id = "kitty";}];
        "2" = [{app_id = "firefox";}];
        "3" = [{app_id = "thunderbird";}];
        "4" = [{app_id = "discord";}];
        "5" = [{app_id = "Beeper";}];
      };

      startup = [
        {command = "${pkgs.kitty}/bin/kitty";}
        {command = "firefox";}
        {command = "thunderbird";}
        {command = "discord";}
        {command = "beeper";}
        {command = "1password";}
      ];
    };
  };

  programs.waybar = {
    enable = true;
    settings = {
      main = {
        height = 24;
        modules-left = ["sway/workspaces" "sway/mode"];
        modules-center = ["sway/window"];
        modules-right = ["pulseaudio" "network" "cpu" "memory" "battery" "tray" "clock"];
        "sway/workspaces" = {
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
        clock = {
          format = "{:%I:%M %p}";
        };
        network = {
          format-wifi = "";
          tooltip-format-wifi = "{essid} ({signalStrength}%)";
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

  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 300;
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }
      {
        timeout = 600;
        command = "${config.systemd.user.systemctlPath} suspend";
      }
    ];
    events = [
      {
        event = "before-sleep";
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }
      {
        event = "lock";
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }
    ];
  };

  services.mako = {
    enable = true;
    font = "sans-serif 9";
    anchor = "bottom-right";
    padding = "10";
    borderRadius = 5;
    backgroundColor = "#eff1f5";
    textColor = "#4c4f69";
    borderColor = "#1e66f5";
    progressColor = "over #ccd0da";

    extraConfig = ''
      [urgency=high]
      border-color=#fe640b
    '';
  };

  programs.swaylock = {
    enable = true;
    settings = {
      color = "1e1e2e";
      font = "sans-serif";
    };
  };

  systemd.user.services.swaybg = {
    Unit = {
      Description = "swaybg background service";
      Documentation = "man:swaybg(1)";
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg -i ${./botw.png} -m fit -c #000000";
      Type = "simple";
    };
    Install.WantedBy = ["sway-session.target"];
  };
}
