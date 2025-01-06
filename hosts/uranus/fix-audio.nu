def is-main-monitor [route] {
  $route.info | any {|e| $e == "DELL U2723QE" }
}

def main [] {
  let device = pw-dump | from json | where info?.props."alsa.id"? == "HDMI" | first
  let current_route = $device.info.params.Route.0

  if (is-main-monitor $current_route) {
    print -e "already routed to correct monitor"
    exit 0
  }

  let desired_route = $device.info.params.EnumRoute | filter {|e| is-main-monitor $e } | first
  pw-cli set-param $device.id Profile ({ index: $desired_route.profiles.0, save: true } | to json)

  let node = pw-dump | from json | where info?.props."device.id"? == $device.id | first
  wpctl set-default $node.id
}
