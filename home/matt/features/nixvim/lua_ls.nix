{
  programs.nixvim = {
    plugins.lsp.servers.lua-ls = {
      enable = true;
      settings = {
        runtime.version = "LuaJIT";
        diagnostics.globals = ["vim"];
      };
    };
  };
}
