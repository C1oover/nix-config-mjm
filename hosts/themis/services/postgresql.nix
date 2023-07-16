{
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    authentication = ''
      # "local" is for Unix domain socket connections only
      local   all             all                                     trust
      # IPv4 local connections:
      host    all             all             127.0.0.1/32            trust
      # IPv6 local connections:
      host    all             all             ::1/128                 trust

      # allow connections from the local network
      host	all		consul		10.0.2.10/32		trust
      host	all		all		10.0.0.0/8		scram-sha-256
    '';
  };

  networking.firewall.allowedTCPPorts = [5432];
}
