{pkgs, ...}: {
  home.packages = with pkgs; [
    vit
    taskwarrior-tui
  ];

  programs.taskwarrior = {
    enable = true;
  };
}
