{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.nomad;

  templateType = with lib;
    {name, ...}: {
      options = {
        destination = mkOption {
          type = types.str;
          default = name;
        };
        source = mkOption {
          type = types.nullOr types.path;
          default = null;
        };
        text = mkOption {
          type = types.nullOr types.lines;
          default = null;
        };
        changeMode = mkOption {
          type = types.enum ["restart" "signal" "noop"];
          default = "restart";
        };
        changeSignal = mkOption {
          type = types.str;
          default = "";
        };
        envVars = mkOption {
          type = types.bool;
          default = false;
        };
        leftDelimiter = mkOption {
          type = types.str;
          default = "{{";
        };
      };
    };

  taskType = with lib;
    {name, ...}: {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
        };
        docker = {
          image = mkOption {
            type = types.nullOr types.singleLineStr;
            default = null;
          };
          args = mkOption {
            type = types.nullOr (types.listOf types.str);
            default = null;
          };
          volumes = mkOption {
            type = types.nullOr (types.listOf types.str);
            default = null;
          };
        };
        ports = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
        };
        env = mkOption {
          type = types.attrs;
          default = {};
        };
        cpu = mkOption {
          type = types.int;
        };
        memory = mkOption {
          type = types.int;
        };
        loggingTag = mkOption {
          type = types.nullOr types.str;
          default = null;
        };
        vault = {
          policies = mkOption {
            type = types.nullOr (types.listOf types.str);
            default = null;
          };
          changeMode = mkOption {
            type = types.nullOr (types.enum ["restart" "signal" "noop"]);
            default = null;
          };
        };
        templates = mkOption {
          type = types.attrsOf (types.submodule templateType);
          default = {};
        };
      };
    };

  serviceCheckType = with lib; {
    options = {
      http = {
        path = mkOption {
          type = types.nullOr types.str;
          default = null;
        };
        port = mkOption {
          type = types.nullOr types.str;
          default = null;
        };
        headers = mkOption {
          type = types.nullOr (types.attrsOf (types.listOf types.str));
          default = null;
        };
      };
      script = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
      };
      interval = mkOption {
        type = types.int;
      };
      timeout = mkOption {
        type = types.int;
      };
      successBeforePassing = mkOption {
        type = types.nullOr types.int;
        default = null;
      };
    };
  };

  serviceType = with lib; {
    options = {
      name = mkOption {
        type = types.str;
      };
      port = mkOption {
        type = types.either types.port types.str;
      };
      task = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      tags = mkOption {
        type = types.listOf types.str;
        default = [];
      };
      checks = mkOption {
        type = types.listOf (types.submodule serviceCheckType);
        default = [];
      };
      metrics = {
        enable = mkEnableOption "prometheus metrics scraping";
        path = mkOption {
          type = types.str;
          default = "/metrics";
        };
        port = mkOption {
          type = types.nullOr types.str;
          default = null;
        };
      };
      connect = {
        enable = mkEnableOption "consul connect";
        upstreams = mkOption {
          type = types.attrsOf types.port;
          default = {};
        };
      };
    };
  };

  portType = with lib;
    {name, ...}: {
      options = {
        label = mkOption {
          type = types.str;
          default = name;
        };
        to = mkOption {
          type = types.nullOr types.port;
          default = null;
        };
        static = mkOption {
          type = types.nullOr types.port;
          default = null;
        };
      };
    };

  taskGroupType = with lib;
    {name, ...}: {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
        };
        count = mkOption {
          type = types.int;
          default = 1;
        };
        architecture = mkOption {
          type = types.nullOr (types.enum ["arm64" "amd64"]);
          default = null;
        };
        nodes = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
        };
        ports = mkOption {
          type = types.attrsOf (types.submodule portType);
          default = {};
        };
        services = mkOption {
          type = types.listOf (types.submodule serviceType);
          default = [];
        };
        tasks = mkOption {
          type = types.attrsOf (types.submodule taskType);
          default = {};
        };
      };
    };

  jobType = with lib;
    {name, ...}: {
      options = {
        id = mkOption {
          type = types.str;
          default = name;
        };
        type = mkOption {
          type = types.enum ["service" "system" "batch"];
          default = "service";
        };
        datacenters = mkOption {
          type = types.listOf types.str;
          default = ["dc1"];
        };
        priority = mkOption {
          type = types.int;
        };
        taskGroups = mkOption {
          type = types.attrsOf (types.submodule taskGroupType);
          default = {};
        };
      };
    };
in {
  options.nomad = {
    jobs = mkOption {
      default = {};
      type = types.attrsOf (types.submodule jobType);
    };
  };

  config = let
    mkTemplateConfig = tmpl:
      {
        EmbeddedTmpl =
          if tmpl.source != null
          then builtins.readFile tmpl.source
          else if tmpl.text != null
          then tmpl.text
          else null;
        DestPath = tmpl.destination;
        ChangeMode = tmpl.changeMode;
        ChangeSignal = tmpl.changeSignal;
        EnvVars = tmpl.envVars;
      }
      // (lib.optionalAttrs (tmpl.leftDelimiter != null) {LeftDelim = tmpl.leftDelimiter;});

    mkDockerTaskOpts = task: {
      Driver = "docker";
      Config =
        (lib.attrsets.filterAttrs (_key: val: val != null) task.docker)
        // (lib.optionalAttrs (task.ports != null) {
          inherit (task) ports;
        })
        // (lib.optionalAttrs (task.loggingTag != null) {
          logging.type = "journald";
          logging.config = [{tag = task.loggingTag;}];
        });
    };

    mkTaskConfig = task:
      {
        Name = task.name;
        Resources.CPU = task.cpu;
        Resources.MemoryMB = task.memory;
        Env = task.env;
        Templates = map mkTemplateConfig (builtins.attrValues task.templates);
      }
      // (lib.optionalAttrs (task.docker.image != null) (mkDockerTaskOpts task))
      // (lib.attrsets.filterAttrs (_key: val: val != {}) {
        Vault =
          (lib.optionalAttrs (task.vault.policies != null) {Policies = task.vault.policies;})
          // (lib.optionalAttrs (task.vault.changeMode != null) {ChangeMode = task.vault.changeMode;});
      });

    mkServiceCheckConfig = svcIdx: svc: checkIdx: check: let
      commonOpts = {
        Interval = check.interval * 1000000000;
        Timeout = check.timeout * 1000000000;
        SuccessBeforePassing = check.successBeforePassing;
      };
    in
      if check.http.path != null
      then
        {
          Type = "http";
          Path = check.http.path;
        }
        // (lib.optionalAttrs (check.http.port != null) {
          PortLabel = check.http.port;
        })
        // (lib.optionalAttrs (check.http.headers != null) {
          Header = check.http.headers;
        })
        // (lib.optionalAttrs svc.connect.enable {
          Expose = true;
          PortLabel = "health_${toString svcIdx}_${toString checkIdx}";
        })
        // commonOpts
      else if check.script != null
      then
        {
          Type = "script";
          Command = builtins.head check.script;
          Args = builtins.tail check.script;
        }
        // commonOpts
      else null;

    mkConnectServiceConfig = i: svc: {
      Connect.SidecarService.Proxy =
        {
          Config.envoy_prometheus_bind_addr = "0.0.0.0:${toString (9102 + i)}";
        }
        // (lib.optionalAttrs svc.metrics.enable {
          ExposeConfig.Path = [
            {
              Path = svc.metrics.path;
              Protocol = "http";
              LocalPathPort = svc.port;
              ListenerPort = "expose";
            }
          ];
        })
        // (lib.optionalAttrs (svc.connect.upstreams != {}) {
          Upstreams =
            lib.attrsets.mapAttrsToList
            (name: port: {
              DestinationName = name;
              LocalBindPort = port;
            })
            svc.connect.upstreams;
        });
    };

    mkServiceConfig = i: svc:
      {
        Name = svc.name;
        PortLabel = toString svc.port;
        TaskName = svc.task;
        Tags = svc.tags;
        Meta =
          (lib.optionalAttrs svc.metrics.enable
            {
              metrics_path = svc.metrics.path;
            }
            // (lib.optionalAttrs (svc.metrics.port != null) {
              metrics_port = "$\${NOMAD_HOST_PORT_${svc.metrics.port}}";
            }))
          // (lib.optionalAttrs svc.connect.enable {
            envoy_metrics_port = "$\${NOMAD_HOST_PORT_envoy_metrics_${toString i}}";
          })
          // (lib.optionalAttrs (svc.connect.enable && svc.metrics.enable) {
            metrics_port = "$\${NOMAD_HOST_PORT_expose}";
          });
        Checks = lib.lists.imap0 (mkServiceCheckConfig i svc) svc.checks;
      }
      // (lib.optionalAttrs svc.connect.enable (mkConnectServiceConfig i svc));

    mkNetworksConfig = tg: let
      getCheckConnectPorts = svcIdx: checkIdx: check:
        lib.optional (check.http.path != null) {
          Label = "health_${toString svcIdx}_${toString checkIdx}";
        };
      getServiceConnectPorts = i: svc:
        lib.optionals svc.connect.enable (
          [
            {
              Label = "envoy_metrics_${toString i}";
              To = 9102 + i;
            }
          ]
          ++ (lib.optional svc.metrics.enable {Label = "expose";})
          ++ (builtins.concatLists (lib.lists.imap0 (getCheckConnectPorts i) svc.checks))
        );
      connectPorts = builtins.concatLists (lib.lists.imap0 getServiceConnectPorts tg.services);

      ports = builtins.attrValues tg.ports;
      dynamicPorts = builtins.filter (p: p.static == null) ports;
      reservedPorts = builtins.filter (p: p.static != null) ports;
    in [
      {
        DNS.Servers = ["10.0.2.47" "10.0.2.48"];
        DynamicPorts =
          (map
            (port:
              {Label = port.label;}
              // (lib.optionalAttrs (port.to != null) {
                To = port.to;
              }))
            dynamicPorts)
          ++ connectPorts;
        ReservedPorts =
          map
          (port: {
            Label = port.label;
            Value = port.static;
          })
          reservedPorts;
        Mode =
          if
            builtins.any
            (s: s.connect.enable)
            tg.services
          then "bridge"
          else "host";
      }
    ];

    mkTaskGroupConfig = tg: {
      Name = tg.name;
      Count = tg.count;
      Constraints =
        lib.lists.optional (tg.architecture != null) {
          LTarget = "$\${attr.cpu.arch}";
          Operand = "=";
          RTarget = tg.architecture;
        }
        ++ lib.lists.optional (tg.nodes != null) {
          LTarget = "$\${node.unique.name}";
          Operand = "regexp";
          RTarget = "^(${builtins.concatStringsSep "|" tg.nodes})$";
        };
      Networks = mkNetworksConfig tg;
      Services = lib.lists.imap0 mkServiceConfig tg.services;
      Tasks = map mkTaskConfig (builtins.attrValues tg.tasks);
    };

    mkJobConfig = job: {
      ID = job.id;
      Type = job.type;
      Datacenters = job.datacenters;
      Priority = job.priority;
      TaskGroups = map mkTaskGroupConfig (builtins.attrValues job.taskGroups);
    };

    mkJobResource = job: let
      jobConfig = mkJobConfig job;
    in {
      jobspec = builtins.toJSON jobConfig;
      json = true;
      detach = false;
    };
  in {
    resource.nomad_job = builtins.mapAttrs (_name: mkJobResource) cfg.jobs;
  };
}
