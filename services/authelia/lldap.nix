{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.authelia;
in
{
  config = mkIf cfg.enable {
    mjm.services.authelia.postgresql.databases = [ "lldap" ];
    mjm.state.services = [ "lldap" ];

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

    systemd.services.lldap.after = [ "postgresql.service" ];

    mjm.spire.tunnels.lldap = {
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
  };
}
