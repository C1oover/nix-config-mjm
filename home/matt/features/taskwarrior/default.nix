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
    config.taskd = {
      ca = ./ca.crt;
      certificate = ./cert.crt;
      key = "$XDG_RUNTIME_DIR/agenix/taskserver.key";
      server = "nemesis.home.mattmoriarity.com:53589";
      credentials = "home/mjm/158e73c7-9492-44cb-b340-508633b860f2";
    };
  };

  age.secrets."taskserver.key".file = ../../../../secrets/taskwarrior-key.age;
}
