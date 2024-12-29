{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    attrValues
    filter
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;

  jsonFormat = pkgs.formats.json { };
  cfg = config.services.consul;

  servicesCfg = jsonFormat.generate "consul-services.json" {
    services = map (svc: svc.serviceConfig) (filter (svc: svc.enable) (attrValues cfg.services));
  };

  hostname = config.networking.hostName;
in
{
  options.services.consul.services = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, config, ... }:
        {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
            };
            id = mkOption {
              type = types.str;
              default = "${name}:${hostname}";
            };
            name = mkOption {
              type = types.str;
              default = name;
            };
            port = mkOption {
              type = types.port;
            };

            metrics = {
              enable = mkEnableOption "scraping metrics with Prometheus";
              path = mkOption {
                type = types.str;
                default = "/metrics";
              };
              port = mkOption {
                type = types.nullOr types.port;
                default = null;
              };
            };

            checks =
              let
                svcId = config.id;
                svcName = config.name;
                svcPort = config.port;
              in
              mkOption {
                default = { };
                type = types.attrsOf (
                  types.submodule (
                    { name, config, ... }:
                    {
                      options = {
                        enable = mkOption {
                          type = types.bool;
                          default = true;
                        };
                        id = mkOption {
                          type = types.str;
                          default = "${svcId}:${name}";
                        };
                        name = mkOption {
                          type = types.str;
                          default = "${svcName} is ready";
                        };
                        intervalSeconds = mkOption {
                          type = types.int;
                          default = 15;
                        };
                        timeoutSeconds = mkOption {
                          type = types.int;
                          default = 10;
                        };

                        http = {
                          url = mkOption {
                            type = types.nullOr types.str;
                            default = null;
                          };
                          path = mkOption {
                            type = types.nullOr types.str;
                            default = null;
                          };
                        };

                        script = {
                          args = mkOption {
                            type = types.nullOr (types.listOf types.str);
                            default = null;
                          };
                        };

                        checkConfig = mkOption {
                          type = types.submodule { freeformType = jsonFormat.type; };
                        };
                      };

                      config = {
                        checkConfig = {
                          id = mkDefault config.id;
                          name = mkDefault config.name;
                          http = mkMerge [
                            (mkIf (config.http.path != null) "http://localhost:${toString svcPort}${config.http.path}")
                            (mkIf (config.http.url != null) config.http.url)
                          ];
                          args = mkIf (config.script.args != null) config.script.args;
                          interval = mkDefault "${toString config.intervalSeconds}s";
                          timeout = mkDefault "${toString config.timeoutSeconds}s";
                        };
                      };
                    }
                  )
                );
              };

            serviceConfig = mkOption {
              type = types.submodule { freeformType = jsonFormat.type; };
            };
          };

          config = {
            serviceConfig = {
              id = mkDefault config.id;
              name = mkDefault config.name;
              port = mkDefault config.port;

              meta = mkIf config.metrics.enable {
                metrics_path = config.metrics.path;
                metrics_port = mkIf (config.metrics.port != null) (toString config.metrics.port);
              };
              checks = mkIf (config.checks != { }) (
                map (chk: chk.checkConfig) (filter (chk: chk.enable) (attrValues config.checks))
              );
            };
          };
        }
      )
    );
    default = { };
  };

  config = mkIf (cfg.services != { }) {
    environment.etc."consul-services.json".source = servicesCfg;
    services.consul.extraConfigFiles = [ "/etc/consul-services.json" ];
  };
}
