return {
  "jose-elias-alvarez/null-ls.nvim",
  opts = function(_, config)
    local nls = require("null-ls")

    if not config.sources then
      config.sources = {}
    end

    if type(config.sources) == "table" then
      vim.list_extend(config.sources, {
        nls.builtins.code_actions.statix,
        nls.builtins.formatting.alejandra,
        nls.builtins.diagnostics.deadnix,
      })
    end
    return config -- return final config table
  end,
}
