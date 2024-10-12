{
  config,
  lib,
  inputs,
  ...
}:
let
  inherit (lib)
    filterAttrs
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optionalAttrs
    types
    ;

  cfg = config.mjm.state;

  isValidForPreservation = _: v: v != null;
in
{
  imports = [ "${inputs.preservation}/module.nix" ];

  options.mjm.state = {
    enablePreservation = mkEnableOption "preservation";

    persistDir = mkOption { type = types.path; };

    directories = mkOption {
      type = types.listOf (
        types.coercedTo types.str (d: { directory = d; }) (
          types.submodule {
            options = {
              directory = mkOption { type = types.str; };
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
  };

  config = mkMerge [
    {
      mjm.state.directories = [
        # important for uids/gids to stay consistent
        {
          directory = "/var/lib/nixos";
          inInitrd = config.mjm.userborn.enable;
        }
        {
          directory = "/var/log";
          inInitrd = true;
        }
      ];

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
    {
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
    }
    (mkIf cfg.enablePreservation {
      preservation = {
        enable = true;
        preserveAt.${cfg.persistDir} = {
          directories = map (filterAttrs isValidForPreservation) cfg.directories;
          files = map (filterAttrs isValidForPreservation) cfg.files;

          # TODO abstract this
          users.matt.directories = [ ".local/share/atuin" ];
        };
      };

      systemd.tmpfiles.settings.preservation = {
        "/home/matt/.local".d = {
          user = "matt";
          group = "users";
          mode = "0755";
        };
        "/home/matt/.local/share".d = {
          user = "matt";
          group = "users";
          mode = "0755";
        };
      };

      age.identityPaths = [ "${cfg.persistDir}/etc/ssh/ssh_host_ed25519_key" ];

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
    })
  ];
}
