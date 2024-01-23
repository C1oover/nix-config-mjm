{ pkgs, ... }:
{
  home.packages = [ (pkgs.callPackage ./jpr.nix { }) ];

  programs.git.userEmail = "matt@slab.com";

  programs.jujutsu.settings = {
    aliases.mine = [
      "log"
      "-r"
      ''@ | main | branches("mjm-")''
    ];
  };
}
