{
  programs.nixvim = {
    plugins.lualine = {
      enable = true;
      ignoreFocus = ["neo-tree"];
      sections.lualine_x = ["filetype"];
    };
  };
}
