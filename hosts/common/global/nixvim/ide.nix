{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.x.nixvim;
in {
  options = with lib; {
    x.nixvim.enableIde = mkEnableOption "IDE features";
  };

  config = {
    programs.nixvim = lib.mkIf cfg.enableIde {
      extraPlugins = with pkgs.vimPlugins; [
        vim-elixir
      ];
    };
  };
}
