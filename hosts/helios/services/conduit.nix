{
  config,
  inputs,
  pkgs,
  ...
}:
{
  mjm.state.directories = [ "/var/lib/private/matrix-conduit" ];

  services.matrix-conduit = {
    enable = true;
    package = inputs.conduit.packages.${pkgs.system}.default;

    settings.global = {
      address = "::";
      server_name = "midna.dev";
      database_backend = "rocksdb";
      log = "info";
    };
  };

  networking.firewall.allowedTCPPorts = [ config.services.matrix-conduit.settings.global.port ];

  services.consul.services.conduit = rec {
    inherit (config.services.matrix-conduit.settings.global) port;

    checks = [
      {
        name = "conduit is ready";
        http = "http://localhost:${toString port}/_matrix/client/versions";
        interval = "15s";
        timeout = "10s";
      }
    ];
  };
}
