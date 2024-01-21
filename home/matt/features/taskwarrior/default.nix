{
  pkgs,
  lib,
  config,
  ...
}: {
  home.packages = with pkgs; [
    vit
    taskwarrior-tui
  ];

  programs.taskwarrior = {
    enable = true;
    config = {
      taskd = {
        ca = "${./ca.crt}";
        certificate = "${./cert.crt}";
        key =
          if pkgs.stdenv.isDarwin
          then "${config.home.homeDirectory}/.config/task/taskserver.key"
          else "$XDG_RUNTIME_DIR/agenix/taskserver.key";
        server = "tasks.midna.dev:53589";
        credentials = "home/mjm/335503bd-9888-481a-b3e9-7d0c54e0b8bc";
      };
      uda.reminder_id.type = "string";
      uda.reminder_id.label = "Reminder";
      uda.next_notification.type = "date";
      uda.next_notification.label = "Notify";
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

  home.file."${config.programs.taskwarrior.dataLocation}/hooks/on-exit-sync".source = lib.getExe (pkgs.writeShellApplication {
    name = "tw-on-exit-sync";
    text = builtins.readFile ./on-exit-sync.sh;
  });
}
