{ pkgs, ... }:
let
  iconMap = pkgs.writeScript "sketchybar-plugin-icon-map" ''
    #!${pkgs.bash}/bin/bash
    ${builtins.readFile sketchybar/plugins/icon_map.sh}
  '';

  batteryPlugin = pkgs.writeScript "sketchybar-plugin-battery" ''
    #!${pkgs.bash}/bin/bash
    source ${sketchybar/colors.sh}
    source ${sketchybar/icons.sh}
    ${builtins.readFile sketchybar/plugins/battery.sh}
  '';

  calendarPlugin = pkgs.writeShellScript "sketchybar-plugin-calendar" (
    builtins.readFile sketchybar/plugins/calendar.sh
  );

  spacePlugin = pkgs.writeScript "sketchybar-plugin-space" ''
    #!${pkgs.bash}/bin/bash
    ${builtins.readFile sketchybar/plugins/space.sh}
  '';

  yabaiPlugin = pkgs.writeScript "sketchybar-plugin-yabai" ''
    #!${pkgs.bash}/bin/bash
    source ${sketchybar/colors.sh}
    source ${sketchybar/icons.sh}
    ICON_MAP=${iconMap}
    YABAI=${pkgs.yabai}/bin/yabai
    JQ=${pkgs.jq}/bin/jq
    ${builtins.readFile sketchybar/plugins/yabai.sh}
  '';
in
{
  services.yabai = {
    enable = true;
    extraConfig = ''
      yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"
      sudo yabai --load-sa

      yabai -m config \
        layout bsp \
        focus_follows_mouse        autofocus    \
        window_opacity             on           \
        active_window_opacity      1.0          \
        normal_window_opacity      0.95         \
        top_padding                12           \
        bottom_padding             12           \
        left_padding               12           \
        right_padding              12           \
        window_gap                 12           \
        window_shadow              float        \
        external_bar               all:0:43     \
        window_border              on           \
        window_border_width        2            \
        window_border_hidpi        off          \
        window_border_radius       11           \
        active_window_border_color 0xffe1e3e4   \
        normal_window_border_color 0xff2a2f38   \
        insert_feedback_color      0xff9dd274

      yabai -m rule --add app="^System Settings$" manage=off

      for _ in $(yabai -m query --spaces | jq '.[].index | select(. > 6)'); do
        yabai -m space --destroy 7
      done

      function setup_space {
        local idx="$1"
        local name="$2"
        local space=

        echo "setup space $idx : $name"

        space=$(yabai -m query --spaces --space "$idx")
        if [ -z "$space" ]; then
          yabai -m space --create
        fi

        yabai -m space "$idx" --label "$name"
      }

      setup_space 1 code
      setup_space 2 web
      setup_space 3 slab
      setup_space 4 social
      setup_space 5 messages
      setup_space 6 other

      yabai -m rule --add app="^iTerm2$" space=^1
      yabai -m rule --add app="^kitty$" space=^1
      yabai -m rule --add app="^Dash$" space=^1
      yabai -m rule --add app="^Safari$" space=^2
      yabai -m rule --add app="^Firefox$" space=^2
      yabai -m rule --add app="^Slab$" space=3
      yabai -m rule --add app="^Slack$" space=4
      yabai -m rule --add app="^Discord$" space=4
      yabai -m rule --add app="^Messages$" space=5
      yabai -m rule --add app="^Beeper$" space=5

      yabai -m signal --add event=window_focused action="sketchybar --trigger window_focus"
      yabai -m signal --add event=window_created action="sketchybar --trigger windows_on_spaces"
      yabai -m signal --add event=window_destroyed action="sketchybar --trigger windows_on_spaces"
    '';
  };

  services.sketchybar = {
    enable = true;
    config = {
      position = "bottom";
      color = "0xa024273a";
      shadow = "on";
      height = 39;
      padding_left = 12;
      padding_right = 12;
      corner_radius = 9;
      margin = 10;
      y_offset = 4;
      blur_radius = 20;
      notch_width = 0;
    };
    extraConfig = ''
      source ${sketchybar/colors.sh}
      source ${sketchybar/icons.sh}

      YABAI=${pkgs.yabai}/bin/yabai
      JQ=${pkgs.jq}/bin/jq

      FONT="SF Pro"
      PADDINGS=3

      defaults=(
        updates=when_shown
        icon.font="$FONT:Bold:14.0"
        icon.color=$ICON_COLOR
        icon.padding_left=$PADDINGS
        icon.padding_right=$PADDINGS
        label.font="$FONT:Semibold:13.0"
        label.color=$LABEL_COLOR
        label.padding_left=$PADDINGS
        label.padding_right=$PADDINGS
        padding_right=$PADDINGS
        padding_left=$PADDINGS
        background.height=30
        background.corner_radius=9
        popup.background.border_width=2
        popup.background.corner_radius=9
        popup.background.border_color=$POPUP_BORDER_COLOR
        popup.background.color=$POPUP_BACKGROUND_COLOR
        popup.blur_radius=20
        popup.background.shadow.drawing=on
      )

      sketchybar --default "''${defaults[@]}"

      BATTERY_PLUGIN=${batteryPlugin}
      CALENDAR_PLUGIN=${calendarPlugin}
      SPACE_PLUGIN=${spacePlugin}
      YABAI_PLUGIN=${yabaiPlugin}

      source ${sketchybar/items/apple.sh}
      source ${sketchybar/items/spaces.sh}
      source ${sketchybar/items/front_app.sh}

      source ${sketchybar/items/calendar.sh}
      source ${sketchybar/items/battery.sh}

      sketchybar --update
      sketchybar --trigger windows_on_spaces
    '';
  };

  services.skhd = {
    enable = true;
    skhdConfig = ''
      ctrl + alt + cmd - 1 : ${pkgs.yabai}/bin/yabai -m space --focus 1
      ctrl + alt + cmd - 2 : ${pkgs.yabai}/bin/yabai -m space --focus 2
      ctrl + alt + cmd - 3 : ${pkgs.yabai}/bin/yabai -m space --focus 3
      ctrl + alt + cmd - 4 : ${pkgs.yabai}/bin/yabai -m space --focus 4
      ctrl + alt + cmd - 5 : ${pkgs.yabai}/bin/yabai -m space --focus 5
      ctrl + alt + cmd - 6 : ${pkgs.yabai}/bin/yabai -m space --focus 6

      ctrl + alt + cmd - left : ${pkgs.yabai}/bin/yabai -m space --focus prev
      ctrl + alt + cmd - right : ${pkgs.yabai}/bin/yabai -m space --focus next

      ctrl + alt + cmd - t : ${pkgs.yabai}/bin/yabai -m window --toggle zoom-parent
      ctrl + alt + cmd - f : ${pkgs.yabai}/bin/yabai -m window --toggle zoom-fullscreen
    '';
  };
}
