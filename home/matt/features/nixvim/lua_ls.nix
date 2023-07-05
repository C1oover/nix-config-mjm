{
  lib,
  config,
  ...
}: let
  cfg = config.x.nixvim;
in {
  programs.nixvim = lib.mkIf cfg.enableIde {
    plugins.lsp.servers.lua-ls = {
      enable = true;
      settings = {
        runtime.version = "LuaJIT";
        diagnostics.globals = ["vim"];
      };
    };
  };
}
