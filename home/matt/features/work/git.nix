{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellApplication {
      name = ",jpr";
      runtimeInputs = with pkgs; [gh coreutils];
      text = ''
        gh pr create --head "$1" --web
      '';
    })
  ];

  programs.git.userEmail = "matt@slab.com";

  programs.jujutsu.settings = {
    aliases.mine = ["log" "-r" "@ | main | branches(\"mjm-\")"];
  };
}
