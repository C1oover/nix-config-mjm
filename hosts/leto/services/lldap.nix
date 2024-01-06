{
  pkgs,
  inputs,
  config,
  ...
}: {
  services.lldap = {
    enable = true;
    # hold back to an old commit that actually builds
    package = inputs.nixos-lldap.legacyPackages.${pkgs.system}.lldap;
    settings = {
      http_url = "https://ldap.home.mattmoriarity.com";
      ldap_base_dn = "dc=home,dc=mattmoriarity,dc=com";
    };
    environmentFile = "/run/secrets/lldap/db.env";
  };

  networking.firewall.allowedTCPPorts = [
    3890
    17170
  ];

  services.consul.services.lldap = {
    port = 17170;

    checks = [
      {
        name = "lldap HTTP API";
        http = "http://localhost:17170/health";
        interval = "30s";
        timeout = "5s";
      }
    ];
  };

  systemd.tmpfiles.rules = ["d /run/secrets/lldap 0700"];

  services.vault-agent.instances.lldap = {
    roleId = "e3b3822d-dd2d-61f3-8d15-25ff21f394b7";
    secretIdFile = config.age.secrets."lldap-approle-secret-id".path;
    templates = [
      {
        contents = ''
          {{ with secret "database/creds/lldap" }}
          LLDAP_DATABASE_URL=postgres://{{ .Data.username }}:{{ .Data.password }}@postgresql.service.consul/lldap
          {{ end }}
        '';
        destination = "/run/secrets/lldap/db.env";
        command = "systemctl restart lldap.service";
      }
    ];
  };

  age.secrets."lldap-approle-secret-id".file = ../../../secrets/lldap-approle-secret-id.age;
}
