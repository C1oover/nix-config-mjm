{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.taskserver;
in
{
  options.mjm.taskserver = {
    enable = mkEnableOption "taskserver";
  };

  config = mkIf cfg.enable {
    mjm.state.directories = [
      {
        directory = config.services.taskserver.dataDir;
        inherit (config.services.taskserver) user group;
      }
    ];

    services.taskserver = {
      enable = true;
      fqdn = "tasks.midna.dev";
      listenHost = "::";
      openFirewall = true;
      organisations.home.users = [ "mjm" ];
    };
  };
}
