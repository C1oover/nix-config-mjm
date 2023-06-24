{
  programs.nixvim.colorschemes.catppuccin = {
    enable = true;
    background.dark = "mocha";
    background.light = "latte";
    flavour = "mocha";
    integrations.barbar = true;
    integrations.gitsigns = true;
    integrations.telescope = true;
    integrations.which_key = true;
  };
}
