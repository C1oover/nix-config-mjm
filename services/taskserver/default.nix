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

    # zone and provider declared by ingress app
    terraform.resource.cloudflare_record = {
      tasks_ipv4 = {
        zone_id = "\${data.cloudflare_zone.external.id}";
        type = "A";
        name = "tasks";
        value = "10.0.2.41";
        proxied = false;
      };
      tasks_ipv6 = {
        zone_id = "\${data.cloudflare_zone.external.id}";
        type = "AAAA";
        name = "tasks";
        value = "2601:282:167f:3eec:acf4:f0ff:feb0:3126";
        proxied = false;
      };
    };
  };
}
