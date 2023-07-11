{
  pkgs,
  lib,
  inputs,
  outputs,
  ...
}: {
  imports = [
    ./global

    ./features/firefox
    ./features/kitty
  ];

  home.packages = with pkgs; [
    discord
    outputs.packages.x86_64-linux.beeper
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
        # "XF86MonBrightnessDown" = "exec light -U 10";
        # "XF86MonBrightnessUp" = "exec light -A 10";
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

      assigns = {
        "1" = [{app_id = "kitty";}];
        "2" = [{app_id = "firefox";}];
        "4" = [{app_id = "discord";}];
        "5" = [{app_id = "Beeper";}];
      };

      startup = [
        {
          command = ''
            swayidle -w \
            timeout 600 '${pkgs.swaylock}/bin/swaylock' \
            timeout 1800 'systemctl suspend' \
            before-sleep '${pkgs.swaylock}/bin/swaylock'
          '';
        }
      ];
    };
  };

  programs.i3status = {
    enable = true;

    general = {
      output_format = "i3bar";
      colors = true;
      color_good = "#a6e3a1";
      color_degraded = "#fab387";
      color_bad = "#f38ba8";
    };

    modules = {
      load = {
        position = 0;
        settings.format = "load: %1min %5min %15min";
      };
      "disk /" = {
        position = 1;
        settings.format = "󰆼 %percentage_used (%free free)";
        settings.low_threshold = "10";
      };
      "volume master" = {
        position = 3;
        settings.device = "pulse";
      };
      "ethernet _first_".enable = false;
      "wireless _first_" = {
        position = 4;
        settings = {
          format_up = "󰖩 %quality %essid %ip";
          format_down = "󰖪 ";
          format_quality = "%d%s";
        };
      };
      "battery all" = {
        position = 6;
        settings = {
          format = "%status %percentage %remaining %emptytime";
          format_down = "No battery";
          status_chr = "⚡ CHR";
          status_bat = "🔋 BAT";
          status_unk = "? UNK";
          status_full = "☻ FULL";
          path = "/sys/class/power_supply/BAT%d/uevent";
          low_threshold = 10;
          last_full_capacity = true;
          hide_seconds = true;
          integer_battery_capacity = true;
        };
      };
      "tztime local" = {
        position = 7;
        settings.format = "%a %d %b %H:%M";
      };
      ipv6.enable = false;
      memory.enable = false;
    };
  };

  home.pointerCursor = {
    name = "Catppuccin-Latte-Light-Cursors";
    package = pkgs.catppuccin-cursors.latteLight;
    size = 48;
    x11 = {
      enable = true;
      defaultCursor = "Catppuccin-Latte-Light-Cursors";
    };
    gtk.enable = true;
  };

  programs.kitty.settings.focus_follows_mouse = "yes";
}
