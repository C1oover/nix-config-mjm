{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatMapAttrsStringSep
    concatStringsSep
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

            cmd = mkOption {
              type = types.path;
            };
            args = mkOption {
              type = types.listOf types.str;
              default = [ ];
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
            cmd = "${pkgs.systemd}/bin/systemctl";
            args = [
              config.systemd.action
              config.systemd.unit
            ];
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
          Type = "exec";
          ExecStart = "${pkgs.spiffe-helper}/bin/spiffe-helper -config $CONFIG_FILE";
          RuntimeDirectory = "certs/%I";
          Restart = "always";
          RestartSec = "5s";
        };
      };
    }

    (mkIf (cfg.certs != { }) {
      systemd.services = mapAttrs' (
        name:
        {
          cmd,
          args,
          user,
          ...
        }:
        {
          name = "spiffe-certs@${name}";
          value = {
            overrideStrategy = "asDropin";
            wantedBy = [ "multi-user.target" ];
            environment.CONFIG_FILE = pkgs.writeText "${name}-spiffe-helper.hcl" ''
              agent_address = "${cfg.agent.socketPath}"
              cmd = "${cmd}"
              cmd_args = "${concatStringsSep " " args}"
              cert_dir = "/run/certs/${name}"
              daemon_mode = true
              svid_file_name = "cert.pem"
              svid_key_file_name = "key.pem"
              svid_bundle_file_name = "bundle.pem"
            '';
            serviceConfig.User = user;
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
