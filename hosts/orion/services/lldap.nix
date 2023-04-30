{ config, ... }: {
  virtualisation.oci-containers.containers = {
    lldap = {
      image = "nitnelave/lldap:stable";
      volumes = [ "lldap_data:/data" ];
      ports = [
        "3890:3890" # ldap
        "17170:17170" # web interface
      ];
    };
  };

  services.consul.extraConfig.services = [
    {
      name = "lldap";
      id = "lldap:${config.networking.hostName}";
      port = 17170;
    }
  ];
}
