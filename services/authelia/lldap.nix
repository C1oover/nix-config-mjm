{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.authelia;
in
{
  config = mkIf cfg.enable {
    mjm.services.authelia.postgresql.databases = [ "lldap" ];
    mjm.state.services = [ "lldap" ];

    services.lldap = {
      enable = true;
      settings = {
        http_url = "https://ldap.home.mattmoriarity.com";
        ldap_base_dn = "dc=home,dc=mattmoriarity,dc=com";
        database_url = "postgres://lldap@%2Frun%2Fpostgresql:5432/lldap";
      };
    };

    systemd.services.lldap.after = [ "postgresql.service" ];

    networking.firewall.allowedTCPPorts = [
      3890
      17170
    ];

    services.consul.services.lldap = {
      port = 17170;

      checks.up = {
        http.path = "/health";
        intervalSeconds = 30;
      };
    };
  };
}
