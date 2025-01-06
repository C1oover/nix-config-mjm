let $terminal = 'com.mitchellh.ghostty'
let $slack = 'com.tinyspeck.slackmacgap'

def get-window-id-for-app [app_id: string] {
  aerospace list-windows --monitor all --app-bundle-id $app_id --format %{window-id} | split row "\n" | get 0
}

def set-app-layout [app_id: string, layout: string] {
  aerospace focus --window-id (get-window-id-for-app $app_id)
  aerospace layout $layout
}

def "main portable" [] {
  set-app-layout $terminal h_accordion
  set-app-layout $slack v_accordion
}

def "main docked" [] {
  set-app-layout $terminal h_tiles
  set-app-layout $slack v_tiles
}

def main [] {}
