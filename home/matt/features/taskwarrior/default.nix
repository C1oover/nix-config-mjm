{
  pkgs,
  lib,
  config,
  ...
}: let
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
      key =
        if pkgs.stdenv.isDarwin
        then "${config.home.homeDirectory}/.config/task/taskserver.key"
        else "$XDG_RUNTIME_DIR/agenix/taskserver.key";
      server = "nemesis.home.mattmoriarity.com:53589";
      credentials = "home/mjm/158e73c7-9492-44cb-b340-508633b860f2";
    };
    extraConfig = ''
      include ${pkgs.taskwarrior}/share/doc/task/rc/dark-gray-blue-256.theme
    '';
  };

  home.activation.link-taskwarrior-key = lib.mkIf pkgs.stdenv.isDarwin (lib.hm.dag.entryAfter ["writeBoundary"] ''
    # need to be able to use getconf
    export PATH=$PATH:/usr/bin
    mkdir -p ${config.home.homeDirectory}/.config/task
    ln -sf ${config.age.secrets."taskserver.key".path} ${config.home.homeDirectory}/.config/task/taskserver.key
  '');

  age.secrets."taskserver.key".file = ../../../../secrets/taskwarrior-key.age;
}
