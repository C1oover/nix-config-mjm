window_state() {
  WINDOW=$($YABAI -m query --windows --window)
  CURRENT=$(echo "$WINDOW" | $JQ '.["stack-index"]')

  args=()
  if [[ $CURRENT -gt 0 ]]; then
    LAST=$($YABAI -m query --windows --window stack.last | $JQ '.["stack-index"]')
    args+=(--set $NAME icon=$YABAI_STACK icon.color=$RED label.drawing=on label=$(printf "[%s/%s]" "$CURRENT" "$LAST"))
    $YABAI -m config active_window_border_color $RED > /dev/null 2>&1 &

  else 
    args+=(--set $NAME label.drawing=off)
    case "$(echo "$WINDOW" | $JQ '.["is-floating"]')" in
      "false")
        if [ "$(echo "$WINDOW" | $JQ '.["has-fullscreen-zoom"]')" = "true" ]; then
          args+=(--set $NAME icon=$YABAI_FULLSCREEN_ZOOM icon.color=$GREEN)
          $YABAI -m config active_window_border_color $GREEN > /dev/null 2>&1 &
        elif [ "$(echo "$WINDOW" | $JQ '.["has-parent-zoom"]')" = "true" ]; then
          args+=(--set $NAME icon=$YABAI_PARENT_ZOOM icon.color=$BLUE)
          $YABAI -m config active_window_border_color $BLUE > /dev/null 2>&1 &
        else
          args+=(--set $NAME icon=$YABAI_GRID icon.color=$ORANGE)
          $YABAI -m config active_window_border_color $WHITE > /dev/null 2>&1 &
        fi
        ;;
      "true")
        args+=(--set $NAME icon=$YABAI_FLOAT icon.color=$MAGENTA)
        $YABAI -m config active_window_border_color $MAGENTA > /dev/null 2>&1 &
        ;;
    esac
  fi

  sketchybar -m "${args[@]}"
}

windows_on_spaces() {
  CURRENT_SPACES="$($YABAI -m query --displays | $JQ -r '.[].spaces | @sh')"

  args=()
  while read -r line
  do
    for space in $line
    do
      icon_strip=" "
      apps=$($YABAI -m query --windows --space $space | $JQ -r ".[].app")
      if [ "$apps" != "" ]; then
        while IFS= read -r app; do
          icon_strip+=" $($ICON_MAP "$app")"
        done <<< "$apps"
      fi
      args+=(--set space.$space label="$icon_strip" label.drawing=on)
    done
  done <<< "$CURRENT_SPACES"

  sketchybar -m "${args[@]}"
}

mouse_clicked() {
  $YABAI -m window --toggle float
  window_state
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked
  ;;
  "forced") exit 0
  ;;
  "window_focus") window_state 
  ;;
  "windows_on_spaces") windows_on_spaces
  ;;
esac
