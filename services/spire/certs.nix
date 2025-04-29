{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatMapAttrsStringSep
    mapAttrs'
    mkMerge
    mkIf
    mkOption
    types
    ;
  cfg = config.mjm.spire;
in
{
  options.mjm.spire.certs = mkOption {
    default = { };
    type = types.attrsOf (
      types.submodule (
        { options, config, ... }:
        {
          options = {
            systemd = {
              unit = mkOption {
                type = types.str;
              };
              action = mkOption {
                type = types.str;
              };
            };

            user = mkOption {
              type = types.str;
              default = "root";
            };
            polkitCheck = mkOption {
              type = types.lines;
              default = "";
              internal = true;
            };
          };

          config = mkIf (options.systemd.unit.isDefined && options.systemd.action.isDefined) {
            polkitCheck = ''
              if (action.id === "org.freedesktop.systemd1.manage-units" &&
                  action.lookup("unit") === "${config.systemd.unit}" &&
                  action.lookup("verb") === "${config.systemd.action}" &&
                  subject.user === "${config.user}") {
                return polkit.Result.YES;
              }
            '';
          };
        }
      )
    );
  };

  config = mkIf cfg.agent.enable (mkMerge [
    {
      systemd.services."spiffe-certs@" = {
        after = [ "spire-agent.service" ];
        wants = [ "spire-agent.service" ];

        serviceConfig = {
          Type = "notify";
          ExecStart = "${pkgs.spiffe-helper}/bin/spiffe-helper -config $CONFIG_FILE";
          RuntimeDirectory = "certs/%I";
          Restart = "always";
          RestartSec = "5s";
          DynamicUser = true;
          NotifyAccess = "all";

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
    }

    (mkIf (cfg.certs != { }) {
      systemd.services = mapAttrs' (
        name: svc:
        let
          systemctl = "${pkgs.systemd}/bin/systemctl";
          command = pkgs.writeShellScript "reload-certs-${name}" ''
            set -x
            ${systemctl} is-active ${svc.systemd.unit} && ${systemctl} ${svc.systemd.action} ${svc.systemd.unit}
            ${pkgs.systemd}/bin/systemd-notify --ready
          '';
        in
        {
          name = "spiffe-certs@${name}";
          value = {
            overrideStrategy = "asDropin";
            wantedBy = [ "multi-user.target" ];
            environment.CONFIG_FILE = pkgs.writeText "${name}-spiffe-helper.hcl" ''
              agent_address = "${cfg.agent.socketPath}"
              cmd = "${command}"
              cert_dir = "/run/certs/${name}"
              daemon_mode = true
              svid_file_name = "cert.pem"
              svid_key_file_name = "key.pem"
              svid_bundle_file_name = "bundle.pem"
            '';
            serviceConfig.User = svc.user;
          };
        }
      ) cfg.certs;

      security.polkit.enable = true;
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          ${concatMapAttrsStringSep "\n" (_: c: c.polkitCheck) cfg.certs}

          return polkit.Result.NOT_HANDLED;
        })
      '';
    })
  ]);
}
