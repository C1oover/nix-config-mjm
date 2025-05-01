{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) getExe mkEnableOption mkIf;
  cfg = config.mjm.work;

  slab = pkgs.writers.writeNuBin ",slab" (
    pkgs.replaceVars ./slab.nu {
      sqlite3 = getExe pkgs.sqlite;
      snappy-decompress = "${pkgs.snappy-decompress}";
    }
  );
in
{
  imports = [
    ./helix.nix
    ./k9s.nix
  ];

  options.mjm.work = {
    enable = mkEnableOption "work-specific configs";
  };

  config = mkIf cfg.enable {
    programs.git.userEmail = "matt@slab.com";

    home.packages = builtins.attrValues {
      inherit slab;
      inherit (pkgs)
        cloudflared
        google-cloud-sdk
        ;
    };

    home.sessionVariables.ASDF_DATA_DIR = "${config.xdg.stateHome}/asdf";

    programs.fish.shellInitLast = ''
      fish_add_path $ASDF_DATA_DIR/shims
    '';

    programs.kitty.darwinLaunchOptions = [
      "--session"
      "${./kitty-session-slab}"
    ];

    xdg.configFile."zellij/layouts/slab.kdl".source = ./work.kdl;
  };
}
