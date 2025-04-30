{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkForce
    mkIf
    ;
in
{
  imports = [ ./clients.nix ];

  options.mjm.garage = {
    enable = mkEnableOption "garage";
  };

  config = mkIf config.mjm.garage.enable {
    mjm.services.garage = {
      vault = {
        enable = true;
      };
    };

    services.garage = {
      enable = true;
      package = pkgs.garage_1_x;
      settings = {
        db_engine = "lmdb";
        replication_factor = 3;
        rpc_bind_addr = "[::]:3901";

        s3_api = {
          s3_region = "home";
          api_bind_addr = "/run/garage/s3.sock";
        };

        consul_discovery = {
          consul_http_addr = "http://127.0.0.1:8500";
          api = "agent";
          service_name = "garage";
        };

        admin.api_bind_addr = "[::]:3903";
      };
      # These aren't used in the `garage` wrapper script :-/
      extraEnvironment = {
        GARAGE_RPC_SECRET_FILE = "%d/garage_rpc_secret";
        GARAGE_ADMIN_TOKEN_FILE = "%d/garage_admin_token";
        # they're not actually world-readable, i promise, it just
        # doesn't like the 440 permissions systemd gives them
        GARAGE_ALLOW_WORLD_READABLE_SECRETS = "true";
      };
    };

    systemd.services.garage.serviceConfig = {
      StateDirectory = mkForce "garage/meta garage/data";
      RuntimeDirectory = "garage";
      LoadCredential = map (k: "garage_${k}:/run/garage-creds.sock") [
        "rpc_secret"
        "admin_token"
      ];
    };

    mjm.state.directories = [ "/var/lib/private/garage/meta" ];

    systemd.sockets.spiffe-garage = {
      wantedBy = [ "sockets.target" ];
      partOf = [ "spiffe-garage.service" ];
      socketConfig.ListenStream = "[::]:3899";
    };

    systemd.services.spiffe-garage = {
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "spiffe-garage.socket"
        "spire-agent.service"
      ];
      requires = [ "spiffe-garage.socket" ];

      environment.SPIFFE_ENDPOINT_SOCKET = "unix:${config.mjm.spire.agent.socketPath}";

      serviceConfig = {
        Type = "notify-reload";
        ExecStart = "${pkgs.spiffe-garage}/bin/spiffe-garage-srv";
        DynamicUser = true;
        Restart = "always";
        LoadCredential = [ "garage_admin_token:/run/garage-creds.sock" ];

        CapabilityBoundingSet = "";
        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        PrivateDevices = true;
        PrivateIPC = true;
        PrivateUsers = "identity";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
        SystemCallErrorNumber = "EPERM";
        SystemCallFilter = [
          "@system-service"
          "~@resources @privileged"
        ];
        UMask = "0077";
      };
    };

    ingress.virtualHosts.garage = {
      upstream = {
        service = {
          name = "garage";
          tag = "s3";
        };
        tls.enable = true;
      };
      enableAuthProxy = false;
      useIPv4Proxy = true;
    };

    mjm.spire.tunnels.garage-s3 = {
      mode = "server";
      listen.port = 3902;
      target.socket = "/run/garage/s3.sock";
      # don't bother with identifying the client, since they need to provide creds
      # anyway, which spiffe-garage will handle.
    };

    environment.systemPackages = builtins.attrValues {
      inherit (pkgs.callPackages ./scripts.nix { garage = config.services.garage.package; }) g;
    };

    networking.firewall.allowedTCPPorts = [
      3899
      3901
      3903
    ];

    services.consul.services = {
      garage = {
        port = 3902;

        metrics.enable = true;
        metrics.port = 3903;

        serviceConfig.tags = [ "s3" ];

        checks.up = {
          http.path = "/health";
          http.port = 3903;
        };
      };

      spiffe-garage = {
        port = 3899;

        # TODO health check
      };
    };

    deployment.consulChecks = [ "garage" ];
    deployment.tests = {
      inherit (pkgs.nixosTests.garage)
        basic1_x
        with-3node-replication1_x
        ;
    };
  };
}
