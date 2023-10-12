{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  hyprland = inputs.hyprland.packages.${pkgs.system}.hyprland;
  pointer = config.home.pointerCursor;

  outputs = {
    # lg = "LG Electronics LG Ultra HD 0x0000ADE2";
    # dell = "Dell Inc. DELL U2715H H7YCC79M07JS";
    # internal = "BOE 0x0BCA";
    lg = "DP-1";
    dell = "DP-2";
    internal = "eDP-1";
  };

  handleEvents = pkgs.writeShellApplication {
    name = "handle-hyprland-events";
    runtimeInputs = [hyprland pkgs.socat];
    text = ''
      handle() {
        case "$1" in monitoradded*)
          hyprctl dispatch moveworkspacetomonitor "1 DP-1"
          hyprctl dispatch moveworkspacetomonitor "2 DP-2"
          ;;
        esac
      }

      socat - "UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | \
        while read -r line; do handle "$line"; done
    '';
  };
in {
  home.packages = with pkgs; [
    kanshi
    pulseaudio
    swaybg
    wob
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = hyprland;

    settings = {
      "$mod" = "SUPER";

      "$wob_socket" = "$XDG_RUNTIME_DIR/wob.sock";
      "$sink_volume" = "pactl get-sink-volume @DEFAULT_SINK@ | grep '^Volume:' | cut -d / -f 2 | tr -d ' ' | sed 's/%//'";
      "$sink_volume_mute" = "pactl get-sink-mute @DEFAULT_SINK@ | sed -En \"/no/ s/.*/$($sink_volume)/p; /yes/ s/.*/0/p\"";

      env = [
        "QT_QPA_PLATFORM,wayland"
        "QT_QPA_PLATFORMTHEME,qt5ct"
        "QT_STYLE_OVERRIDE,kvantum"
        "_JAVA_AWT_WM_NONREPARENTING,1"
        "MOZ_DBUS_REMOTE,1"
        "NIXOS_OZONE_WL,1"
      ];

      exec-once = [
        "hyprctl setcursor ${pointer.name} ${toString pointer.size}"
        "waybar"
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "rm -f $wob_socket && mkfifo $wob_socket && tail -f $wob_socket | wob"
        "swaybg -i ${./botw.png} -m fit -c ##000000"
        "${handleEvents}"

        "[workspace 1 silent] kitty"
        "[workspace 1 silent] firefox"
        "[workspace 1 silent] 1password"
        "[workspace 2 silent] thunderbird"
        "[workspace 2 silent] discord"
        "[workspace 2 silent] beeper"
      ];

      xwayland.force_zero_scaling = true;

      input = {
        follow_mouse = true;
        kb_options = "ctrl:nocaps";
        touchpad = {
          natural_scroll = true;
          clickfinger_behavior = true;
          tap-to-click = false;
        };
      };

      general = {
        gaps_in = 4;
        gaps_out = 8;
        resize_on_border = true;
      };

      decoration = {
        rounding = 8;
      };

      group = {
        "col.border_inactive" = "0xff${config.colorScheme.colors.base07}";
        "col.border_active" = "0xff${config.colorScheme.colors.base0E}";
        groupbar = {
          font_size = 16;
          gradients = false;
          text_color = "0xff${config.colorScheme.colors.base05}";
          "col.inactive" = "0xff${config.colorScheme.colors.base07}";
          "col.active" = "0xff${config.colorScheme.colors.base0E}";
        };
      };

      bindm = [
        "$mod,mouse:272,movewindow"
        "$mod ALT,mouse:272,resizewindow"
      ];

      bind =
        [
          "$mod SHIFT,E,exec,pkill Hyprland"
          "$mod,Q,killactive"
          "$mod,F,fullscreen"
          "$mod SHIFT,F,togglefloating"
          "$mod,G,togglegroup"
          "$mod,N,changegroupactive,f"
          "$mod,P,changegroupactive,b"
          "$mod,left,movefocus,l"
          "$mod,right,movefocus,r"
          "$mod,up,movefocus,u"
          "$mod,down,movefocus,d"
          "$mod SHIFT,left,movewindoworgroup,l"
          "$mod SHIFT,right,movewindoworgroup,r"
          "$mod SHIFT,up,movewindoworgroup,u"
          "$mod SHIFT,down,movewindoworgroup,d"
          "$mod ALT,left,movecurrentworkspacetomonitor,l"
          "$mod ALT,right,movecurrentworkspacetomonitor,r"
          "$mod ALT,up,movecurrentworkspacetomonitor,u"
          "$mod ALT,down,movecurrentworkspacetomonitor,d"
          "ALT,Tab,cyclenext"
          "$mod,Tab,changegroupactive,f"
          "$mod,Minus,splitratio,-0.1"
          "$mod,Equal,splitratio,+0.1"
          "$mod,s,togglespecialworkspace"
          "$mod SHIFT,s,movetoworkspacesilent,special"
          "$mod,Return,exec,kitty"
          "$mod,c,exec,clipman pick -t CUSTOM --tool-args='rofi -dmenu -p clip'"
          "$mod,d,exec,rofi-launcher"
          ",XF86AudioRaiseVolume,exec,pactl set-sink-volume @DEFAULT_SINK@ +4% && $sink_volume > $wob_socket"
          ",XF86AudioLowerVolume,exec,pactl set-sink-volume @DEFAULT_SINK@ -4% && $sink_volume > $wob_socket"
          ",XF86AudioMute,exec,pactl set-sink-mute @DEFAULT_SINK@ toggle && $sink_volume_mute > $wob_socket"
          ",XF86MonBrightnessDown,exec,light -U 5 && light -G | cut -d'.' -f1 > $wob_socket"
          ",XF86MonBrightnessUp,exec,light -A 5 && light -G | cut -d'.' -f1 > $wob_socket"
          ",Print,exec,grim"
          "SHIFT,Print,exec,grim -g \"$(slurp)\""
        ]
        ++ (lib.lists.flatten (builtins.genList (
            x: let
              c = (x + 1) / 10;
              ws = builtins.toString (x + 1 - (c * 10));
            in [
              "$mod,${ws},workspace,${toString (x + 1)}"
              "$mod SHIFT,${ws},movetoworkspace,${toString (x + 1)}"
            ]
          )
          10));

      # bindl = let
      #   monitorctl = lib.getExe (pkgs.writeShellApplication {
      #     name = "monitorctl";
      #     runtimeInputs = [pkgs.jq hyprland];
      #     text = builtins.readFile ./monitorctl.sh;
      #   });
      # in [
      #   ",switch:off:Lid Switch,exec,${monitorctl} on"
      #   ",switch:on:Lid Switch,exec,${monitorctl} off"
      # ];

      # monitor = [
      #   "DP-1,preferred,1440x0,2"
      #   "DP-2,preferred,0x0,1,transform,3"
      #   ",preferred,auto,auto"
      # ];

      windowrulev2 = [
        "float,class:(controku)"
      ];
    };
  };

  systemd.user.services.swayidle.Install.WantedBy = lib.mkForce ["hyprland-session.target"];

  services.kanshi = {
    enable = true;
    systemdTarget = "hyprland-session.target";
    profiles = {
      none = {
        exec = [
          "${hyprland}/bin/hyprctl keyword monitor ${outputs.internal},preferred,auto,auto"
        ];
      };
      anything = {
        outputs = [
          {
            criteria = "*";
          }
        ];
        exec = [
          "${hyprland}/bin/hyprctl keyword monitor ${outputs.internal},preferred,auto,auto"
        ];
      };
      laptop = {
        outputs = [
          {
            criteria = outputs.internal;
          }
        ];
      };
      lg = {
        outputs = [
          {
            criteria = outputs.lg;
            scale = 2.0;
          }
        ];
        exec = [
          "${hyprland}/bin/hyprctl keyword monitor ${outputs.internal},preferred,auto,auto"
        ];
      };
      dell = {
        outputs = [
          {
            criteria = outputs.dell;
            transform = "270";
          }
        ];
        exec = [
          "${hyprland}/bin/hyprctl keyword monitor ${outputs.internal},preferred,auto,auto"
        ];
      };
      desk = {
        outputs = [
          {
            criteria = outputs.lg;
            scale = 2.0;
            position = "1440,0";
          }
          {
            criteria = outputs.dell;
            position = "0,0";
            transform = "270";
          }
          {
            criteria = outputs.internal;
            status = "disable";
          }
        ];
        exec = [
          "${hyprland}/bin/hyprctl dispatch moveworkspacetomonitor '1 ${outputs.lg}'"
          "${hyprland}/bin/hyprctl dispatch moveworkspacetomonitor '2 ${outputs.dell}'"
        ];
      };
      desk2 = {
        outputs = [
          {
            criteria = outputs.lg;
            scale = 2.0;
            position = "1440,0";
          }
          {
            criteria = outputs.dell;
            position = "0,0";
            transform = "270";
          }
        ];
        exec = [
          "${hyprland}/bin/hyprctl dispatch moveworkspacetomonitor '1 ${outputs.lg}'"
          "${hyprland}/bin/hyprctl dispatch moveworkspacetomonitor '2 ${outputs.dell}'"
        ];
      };
    };
  };
}
