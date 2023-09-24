{pkgs, ...}: let
  task-add-laundry = pkgs.writeShellApplication {
    name = "task-add-laundry";
    runtimeInputs = with pkgs; [taskwarrior coreutils];
    text = builtins.readFile ./task-add-laundry.sh;
  };
in {
  home.packages = with pkgs; [
    vit
    taskwarrior-tui
    task-add-laundry
  ];

  programs.taskwarrior = {
    enable = true;
  };
}
