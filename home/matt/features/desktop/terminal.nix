{ lib, config, ... }:
let
  inherit (lib) mkDefault mkIf;
  cfg = config.mjm.desktop;
in
{
  config = mkIf cfg.enable { mjm.terminal.enable = mkDefault true; };
}
