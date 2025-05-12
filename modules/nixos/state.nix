{
  config,
  lib,
  inputs,
  ...
}:
let
  inherit (lib)
    any
    filterAttrs
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optional
    optionalAttrs
    types
    ;

  cfg = config.mjm.state;

  isValidForPreservation = k: v: k != "tag" && v != null;
in
{
  imports = [ "${inputs.preservation}/module.nix" ];

  options.mjm.state = {
    enablePreservation = mkEnableOption "preservation";

    persistDir = mkOption { type = types.path; };

    directories = mkOption {
      type = types.listOf (
        types.coercedTo types.str (d: { directory = d; }) (
          types.submodule (
            { config, ... }:
            {
              options = {
                directory = mkOption { type = types.str; };
                tag = mkOption {
                  type = types.str;
                  default = builtins.baseNameOf config.directory;
                };
                user = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                };
                group = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                };
                mode = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                };
                inInitrd = mkOption {
                  type = types.bool;
                  default = false;
                };
              };
            }
          )
        )
      );
      default = [ ];
    };

    files = mkOption {
      type = types.listOf (
        types.coercedTo types.str (f: { file = f; }) (
          types.submodule {
            options = {
              file = mkOption { type = types.str; };
              user = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
              group = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
              mode = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
              inInitrd = mkOption {
                type = types.bool;
                default = false;
              };
            };
          }
        )
      );
      default = [ ];
    };

    services = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

    tmpfsRoot = {
      enable = mkEnableOption "root FS using tmpfs";

      size = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
    };
  };

  config = mkMerge [
    {
      mjm.state.directories =
        [
          # important for uids/gids to stay consistent
          {
            directory = "/var/lib/nixos";
            inInitrd = true;
          }
          "/var/lib/systemd"
        ]
        ++ optional (!config.mjm.minimal.enable) {
          directory = "/var/log";
          inInitrd = true;
        };

      mjm.state.files = [
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
        {
          file = "/etc/ssh/ssh_host_ed25519_key";
          mode = "0600";
        }
        {
          file = "/etc/ssh/ssh_host_rsa_key";
          mode = "0600";
        }
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    }
    (mkIf (!config.mjm.minimal.enable) {
      mjm.state.directories =
        let
          mkDirectory =
            svcName:
            let
              svc = config.systemd.services.${svcName};
              stateDir = svc.serviceConfig.StateDirectory;
              isDynamic = svc.serviceConfig.DynamicUser or false;
              user = svc.serviceConfig.User or null;
              group = svc.serviceConfig.Group or null;
            in
            {
              directory = if isDynamic then "/var/lib/private/${stateDir}" else "/var/lib/${stateDir}";
            }
            // optionalAttrs (!isDynamic && user != null) { inherit user; }
            // optionalAttrs (!isDynamic && group != null) { inherit group; };
        in
        map mkDirectory cfg.services;
    })
    (mkIf cfg.enablePreservation {
      preservation = {
        enable = true;
        preserveAt.${cfg.persistDir} = {
          directories = map (filterAttrs isValidForPreservation) cfg.directories;
          files = map (filterAttrs isValidForPreservation) cfg.files;

          # TODO abstract this
          users.${config.mjm.username}.directories = mkIf (!any (d: d.directory == "/home") cfg.directories) [
            ".local/share/atuin"
          ];
        };
      };

      systemd.tmpfiles.settings.preservation = {
        "/home/${config.mjm.username}/.local".d = {
          user = config.mjm.username;
          group = "users";
          mode = "0755";
        };
        "/home/${config.mjm.username}/.local/share".d = {
          user = config.mjm.username;
          group = "users";
          mode = "0755";
        };
      };

      security.sudo.extraConfig = ''
        Defaults lecture = never
      '';

      # point directly at the keys on the persist path, to avoid a race where sshd
      # starts before the host keys are mounted into place
      services.openssh.hostKeys = [
        {
          bits = 4096;
          path = "${cfg.persistDir}/etc/ssh/ssh_host_rsa_key";
          type = "rsa";
        }
        {
          path = "${cfg.persistDir}/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];

      boot.initrd.systemd.suppressedUnits = [ "systemd-machine-id-commit.service" ];
      systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

      fileSystems."/" = mkIf cfg.tmpfsRoot.enable {
        device = "none";
        fsType = "tmpfs";
        options = [
          "defaults"
          "mode=755"
        ] ++ optional (cfg.tmpfsRoot.size != null) "size=${cfg.tmpfsRoot.size}";
      };
    })
  ];
}
