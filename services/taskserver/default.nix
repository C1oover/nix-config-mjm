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
    mjm.services.taskserver = { };
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

    terraform.resource.desec_rrset = {
      tasks_a = {
        domain = "\${desec_domain.midna-dev.id}";
        type = "A";
        subname = "tasks";
        records = [ "10.0.2.41" ];
        ttl = 3600;
      };
      tasks_aaaa = {
        domain = "\${desec_domain.midna-dev.id}";
        type = "AAAA";
        subname = "tasks";
        records = [ "2601:282:167f:3eec:acf4:f0ff:feb0:3126" ];
        ttl = 3600;
      };
    };
  };
}
