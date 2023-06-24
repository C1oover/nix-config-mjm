{
  programs.nixvim = {
    plugins.null-ls = {
      enable = true;

      sources = {
        code_actions = {
          shellcheck.enable = true;
          statix.enable = true;
        };
        diagnostics = {
          deadnix.enable = true;
          shellcheck.enable = true;
        };
        formatting = {
          prettier.enable = true;
          shfmt.enable = true;
          stylua.enable = true;
        };
      };
    };
  };
}
