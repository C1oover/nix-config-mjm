local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.check_for_updates = false

config.color_scheme = 'Catppuccin Mocha'
config.font = wezterm.font 'Cascadia Code'
config.font_size = vars.font_size

config.window_frame = {
  font_size = vars.font_size,
  inactive_titlebar_bg = vars.colors.base01,
  active_titlebar_bg = vars.colors.base00,
}

config.command_palette_bg_color = vars.colors.base01
config.command_palette_fg_color = vars.colors.base05
config.command_palette_font_size = vars.font_size

config.default_prog = { "/etc/profiles/per-user/matt/bin/zsh", "--login", "--interactive" }

config.term = "wezterm"
config.enable_kitty_keyboard = true

local act = wezterm.action

config.keys = {
  { key = 'UpArrow', mods = 'SHIFT', action = act.ScrollToPrompt(-1) },
  { key = 'DownArrow', mods = 'SHIFT', action = act.ScrollToPrompt(1) },
}

config.mouse_bindings = {
  {
    event = { Down = { streak = 3, button = 'Left' } },
    action = act.SelectTextAtMouseCursor('SemanticZone'),
    mods = 'NONE',
  },
}

return config

