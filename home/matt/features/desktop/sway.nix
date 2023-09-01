{
  pkgs,
  lib,
  inputs,
  config,
  ...
}: {
  home.packages = with pkgs; [
    bemenu
    swaybg
  ];

  wayland.windowManager.sway = let
    displayLG = "LG Electronics LG Ultra HD 0x0000ADE2";
    displayDell = "Dell Inc. DELL U2715H H7YCC79M07JS";
    displayInternal = "eDP-1";

    fixDisplayState = pkgs.writeShellScript "fix-display-state" ''
      if ${lib.getExe pkgs.gnugrep} -q /proc/acpi/button/lid/LID0/state; then
        ${pkgs.sway}/bin/swaymsg output ${displayInternal} enable
      else
        ${pkgs.sway}/bin/swaymsg output ${displayInternal} disable
      fi
    '';
  in {
    enable = true;
    package = null;

    extraConfigEarly = ''
      include ${inputs.catppuccin-i3}/themes/catppuccin-mocha
      set $WOBSOCK $XDG_RUNTIME_DIR/wob.sock
    '';

    config = let
      mod = "Mod4";
      terminal = "${pkgs.kitty}/bin/kitty";
      bemenuArgs = ''--fb "#1e1e2e" --ff "#94e2d5" --nb "#1e1e2e" --nf "#f5e0dc" --tb "#1e1e2e" --hb "#1e1e2e" --tf "#cba6f7" --hf "#89b4fa" --nf "#f5e0dc" --af "#f5e0dc" --ab "#1e1e2e"'';
      menu = "${pkgs.bemenu}/bin/bemenu-run -i -l 20 -p run ${bemenuArgs}";
      pactl = "${pkgs.pulseaudio}/bin/pactl";
    in {
      inherit terminal menu;
      modifier = mod;

      colors = {
        focused = {
          border = "$mauve";
          background = "$base";
          text = "$text";
          indicator = "$rosewater";
          childBorder = "$mauve";
        };
        focusedInactive = {
          border = "$lavender";
          background = "$base";
          text = "$text";
          indicator = "$rosewater";
          childBorder = "$lavender";
        };
        unfocused = {
          border = "$lavender";
          background = "$base";
          text = "$text";
          indicator = "$rosewater";
          childBorder = "$lavender";
        };
        urgent = {
          border = "$peach";
          background = "$base";
          text = "$peach";
          indicator = "$overlay0";
          childBorder = "$peach";
        };
      };

      gaps.inner = 4;

      keybindings = lib.mkOptionDefault {
        "XF86MonBrightnessDown" = "exec light -U 5 && light -G | cut -d'.' -f1 > $WOBSOCK";
        "XF86MonBrightnessUp" = "exec light -A 5 && light -G | cut -d'.' -f1 > $WOBSOCK";
        "XF86AudioRaiseVolume" = "exec ${pactl} set-sink-volume @DEFAULT_SINK@ +4% && ${pactl} get-sink-volume @DEFAULT_SINK@ | head -n1 | awk '{print substr($5, 1, length($5) - 1)}' > $WOBSOCK";
        "XF86AudioLowerVolume" = "exec ${pactl} set-sink-volume @DEFAULT_SINK@ -4% && ${pactl} get-sink-volume @DEFAULT_SINK@ | head -n1 | awk '{print substr($5, 1, length($5) - 1)}' > $WOBSOCK";
        "XF86AudioMute" = "exec ${pactl} set-sink-mute @DEFAULT_SINK@ toggle && ${pactl} get-sink-volume @DEFAULT_SINK@ | head -n1 | awk '{print substr($5, 1, length($5) - 1)}' > $WOBSOCK";

        "${mod}+c" = "exec ${pkgs.clipman}/bin/clipman pick -t bemenu -T'${bemenuArgs}'";

        "Print" = "exec ${pkgs.grim}/bin/grim";
        "Shift+Print" = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\"";
      };

      input."type:keyboard" = {
        xkb_options = "caps:ctrl_modifier";
      };

      input."type:touchpad" = {
        click_method = "clickfinger";
        middle_emulation = "disabled";
        natural_scroll = "enabled";
      };

      output.${displayDell} = {
        position = "0 0";
        transform = "90";
      };

      output.${displayLG} = {
        position = "1440 0";
        scale = "2";
      };

      bars = [
        {command = "${pkgs.waybar}/bin/waybar";}
      ];

      assigns = {
        "1" = [{app_id = "kitty";} {app_id = "firefox";}];
        "2" = [{app_id = "thunderbird";} {app_id = "discord";} {app_id = "Beeper";}];
      };

      workspaceOutputAssign = [
        {
          workspace = "1";
          output = [displayLG displayInternal];
        }
        {
          workspace = "2";
          output = [displayDell displayInternal];
        }
      ];

      startup = [
        {command = "${pkgs.kitty}/bin/kitty";}
        {command = "firefox";}
        {command = "thunderbird";}
        {command = "discord";}
        {command = "beeper";}
        {command = "1password";}

        {command = "${pkgs.coreutils}/bin/rm -f $WOBSOCK && ${pkgs.coreutils}/bin/mkfifo $WOBSOCK && ${pkgs.coreutils}/bin/tail -f $WOBSOCK | ${pkgs.wob}/bin/wob";}
        {command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";}
        {
          command = "${fixDisplayState}";
          always = true;
        }
      ];
    };

    extraConfig = ''
      for_window [instance="dolphin-emu" title="OpenGL"] \
        inhibit_idle visible

      bindswitch --reload --locked lid:on output ${displayInternal} disable
      bindswitch --reload --locked lid:off output ${displayInternal} enable
    '';
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

  services.clipman.enable = true;
}
