{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  hyprland = inputs.hyprland.packages.${pkgs.system}.hyprland;
  pointer = config.home.pointerCursor;
  colors = import ./hyprland-colors.nix;

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
    pulseaudio
    swaybg
    wob
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = hyprland;

    settings =
      colors
      // {
        "$mod" = "SUPER";

        "$wob_socket" = "$XDG_RUNTIME_DIR/wob.sock";
        "$sink_volume" = "pactl get-sink-volume @DEFAULT_SINK@ | grep '^Volume:' | cut -d / -f 2 | tr -d ' ' | sed 's/%//'";
        "$sink_volume_mute" = "pactl get-sink-mute @DEFAULT_SINK@ | sed -En \"/no/ s/.*/$($sink_volume)/p; /yes/ s/.*/0/p\"";

        env = [
          "QT_OPA_PLATFORM,wayland"
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
          "col.group_border" = "$lavender";
          "col.group_border_active" = "$mauve";
          resize_on_border = true;
        };

        decoration = {
          rounding = 8;
        };

        misc = {
          groupbar_titles_font_size = 16;
          groupbar_gradients = false;
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

        bindl = let
          monitorctl = lib.getExe (pkgs.writeShellApplication {
            name = "monitorctl";
            runtimeInputs = [pkgs.jq hyprland];
            text = builtins.readFile ./monitorctl.sh;
          });
        in [
          ",switch:off:Lid Switch,exec,${monitorctl} on"
          ",switch:on:Lid Switch,exec,${monitorctl} off"
        ];

        monitor = [
          "DP-1,preferred,1440x0,2"
          "DP-2,preferred,0x0,1,transform,3"
          ",preferred,auto,auto"
        ];
      };
  };

  systemd.user.services.swayidle.Install.WantedBy = lib.mkForce ["hyprland-session.target"];
}
