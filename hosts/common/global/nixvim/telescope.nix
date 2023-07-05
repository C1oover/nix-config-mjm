{
  programs.nixvim = {
    plugins.telescope = {
      enable = true;
      keymaps = {
        "<leader>f<cr>" = "resume";
        "<leader>fb" = "buffers";
        "<leader>ff" = "find_files";
        "<leader>fg" = "git_files";
        "<leader>fr" = "registers";
        "<leader>fw" = "live_grep";
      };
      defaults = {
        sorting_strategy = "ascending";
        layout_config = {
          horizontal = {
            prompt_position = "top";
            preview_width = 0.55;
          };
          vertical = {
            mirror = false;
          };
          width = 0.87;
          height = 0.80;
          preview_cutoff = 120;
        };
        mappings = {
          i = {
            "<C-n>" = {__raw = "require('telescope.actions').cycle_history_next";};
            "<C-p>" = {__raw = "require('telescope.actions').cycle_history_prev";};
            "<C-j>" = {__raw = "require('telescope.actions').move_selection_next";};
            "<C-k>" = {__raw = "require('telescope.actions').move_selection_previous";};
          };
          n = {
            "q" = {__raw = "require('telescope.actions').close";};
          };
        };
      };
      extensions.fzf-native.enable = true;
    };

    colorschemes.catppuccin.integrations.telescope = true;
  };
}
