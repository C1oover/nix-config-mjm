{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.work;
in
{
  config = mkIf cfg.enable {
    home.packages = [ (pkgs.callPackage ./jpr.nix { }) ];

    programs.git.userEmail = "matt@slab.com";

    programs.jujutsu.settings = {
      aliases.mine = [
        "log"
        "-r"
        ''@ | main | branches("mjm-")''
      ];
      aliases.wip = [
        "log"
        "-r"
        "wip()"
      ];
      revset-aliases = {
        "wip()" = "mine() & ~(::immutable_heads())";
      };
    };
  };
}
