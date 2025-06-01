{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.cloover.authelia;

  trustDomain = config.cloover.spire.agent.trustDomain;
in
{
  config = mkIf cfg.enable {
    cloover.services.authelia.postgresql.databases = [ "lldap" ];
    cloover.state.directories = [
      {
        directory = "/var/lib/private/lldap";
        user = "nobody";
        group = "nogroup";
      }
    ];

    ingress.virtualHosts.users = {
      upstream = {
        service.name = "lldap";
        tls.enable = true;
      };

      enableAuthProxy = false;
    };

    services.lldap = {
      enable = true;
      settings = {
        http_host = "::1";
        http_port = 27170;
        http_url = "https://users.midna.dev";
        ldap_host = "::1";
        ldap_base_dn = "dc=home,dc=mattmoriarity,dc=com";
        database_url = "postgres://lldap@%2Frun%2Fpostgresql:5432/lldap";
      };
    };

    systemd.services.lldap = {
      startLimitIntervalSec = 0;
      after = [ "postgresql.service" ];
      serviceConfig = {
        Restart = "always";
        RestartSec = "15s";
      };
    };

    cloover.spire.tunnels.lldap = {
      id = "lldap";
      mode = "server";
      listen.port = 17170;
      target.port = 27170;
      allowIngress = true;
    };

    services.consul.services.lldap = {
      port = 17170;

      checks.up = {
        http.path = "/health";
        http.port = 27170;
        intervalSeconds = 30;
      };
    };

    cloover.spire.entries.authelia-lldap = {
      spiffe_id = "spiffe://${trustDomain}/svc/lldap";
      parent_id = "spiffe://${trustDomain}/svc/authelia";
    };
  };
}
