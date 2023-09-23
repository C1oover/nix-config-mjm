# Hyprland crashes if you disable the only monitor:
# https://github.com/hyprwm/Hyprland/issues/1887
# so I check how many there are before trying to mess around with that.

monitor_count=$(hyprctl monitors -j | jq length)

if [ "$monitor_count" = "1" ]; then
  echo "only one monitor, doing nothing." >&2
  exit 0
fi

case "$1" in
on)
  hyprctl keyword monitor eDP-1,preferred,auto,auto
  ;;
off)
  hyprctl keyword monitor eDP-1,disable
  ;;
esac
