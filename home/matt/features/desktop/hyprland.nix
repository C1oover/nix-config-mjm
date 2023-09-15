{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  pointer = config.home.pointerCursor;
  bemenuArgs = builtins.replaceStrings ["#"] ["##"] ''--fn "sans-serif 10" --fb "#1e1e2e" --ff "#94e2d5" --nb "#1e1e2e" --nf "#f5e0dc" --tb "#1e1e2e" --hb "#1e1e2e" --tf "#cba6f7" --hf "#89b4fa" --nf "#f5e0dc" --af "#f5e0dc" --ab "#1e1e2e"'';
in {
  home.packages = with pkgs; [
    pulseaudio
    swaybg
    wob
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;

    settings = {
      "$mod" = "SUPER";

      "$wob_socket" = "$XDG_RUNTIME_DIR/wob.sock";
      "$sink_volume" = "pactl get-sink-volume @DEFAULT_SINK@ | grep '^Volume:' | cut -d / -f 2 | tr -d ' ' | sed 's/%//'";
      "$sink_volume_mute" = "pactl get-sink-mute @DEFAULT_SINK@ | sed -En \"/no/ s/.*/$($sink_volume)/p; /yes/ s/.*/0/p\"";

      "$rosewaterAlpha" = "f5e0dc";
      "$flamingoAlpha" = "f2cdcd";
      "$pinkAlpha" = "f5c2e7";
      "$mauveAlpha" = "cba6f7";
      "$redAlpha" = "f38ba8";
      "$maroonAlpha" = "eba0ac";
      "$peachAlpha" = "fab387";
      "$yellowAlpha" = "f9e2af";
      "$greenAlpha" = "a6e3a1";
      "$tealAlpha" = "94e2d5";
      "$skyAlpha" = "89dceb";
      "$sapphireAlpha" = "74c7ec";
      "$blueAlpha" = "89b4fa";
      "$lavenderAlpha" = "b4befe";

      "$textAlpha" = "cdd6f4";
      "$subtext1Alpha" = "bac2de";
      "$subtext0Alpha" = "a6adc8";

      "$overlay2Alpha" = "9399b2";
      "$overlay1Alpha" = "7f849c";
      "$overlay0Alpha" = "6c7086";

      "$surface2Alpha" = "585b70";
      "$surface1Alpha" = "45475a";
      "$surface0Alpha" = "313244";

      "$baseAlpha" = "1e1e2e";
      "$mantleAlpha" = "181825";
      "$crustAlpha" = "11111b";

      "$rosewater" = "0xfff5e0dc";
      "$flamingo" = "0xfff2cdcd";
      "$pink" = "0xfff5c2e7";
      "$mauve" = "0xffcba6f7";
      "$red" = "0xfff38ba8";
      "$maroon" = "0xffeba0ac";
      "$peach" = "0xfffab387";
      "$yellow" = "0xfff9e2af";
      "$green" = "0xffa6e3a1";
      "$teal" = "0xff94e2d5";
      "$sky" = "0xff89dceb";
      "$sapphire" = "0xff74c7ec";
      "$blue" = "0xff89b4fa";
      "$lavender" = "0xffb4befe";

      "$text" = "0xffcdd6f4";
      "$subtext1" = "0xffbac2de";
      "$subtext0" = "0xffa6adc8";

      "$overlay2" = "0xff9399b2";
      "$overlay1" = "0xff7f849c";
      "$overlay0" = "0xff6c7086";

      "$surface2" = "0xff585b70";
      "$surface1" = "0xff45475a";
      "$surface0" = "0xff313244";

      "$base" = "0xff1e1e2e";
      "$mantle" = "0xff181825";
      "$crust" = "0xff11111b";

      env = [
        "QT_OPA_PLATFORM,wayland"
        "_JAVA_AWT_WM_NONREPARENTING,1"
        "MOZ_DBUS_REMOTE,1"
        "NIXOS_OZONE_WL,1"
        "BEMENU_OPTS,${bemenuArgs}"
      ];

      exec-once = [
        "hyprctl setcursor ${pointer.name} ${toString pointer.size}"
        "waybar"
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "rm -f $wob_socket && mkfifo $wob_socket && tail -f $wob_socket | wob"
        "swaybg -i ${./botw.png} -m fit -c ##000000"

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
          "ALT,Tab,cyclenext"
          "$mod,Tab,changegroupactive,f"
          "$mod,Return,exec,kitty"
          "$mod,c,exec,clipman pick -t bemenu"
          "$mod,d,exec,bemenu-run -i -l 20 -p run"
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
    };
  };

  systemd.user.services.swayidle.Install.WantedBy = lib.mkForce ["hyprland-session.target"];
}
