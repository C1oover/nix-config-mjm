{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.services.vault-agent;
  vaultAgentOpts = with lib;
    { name, ... }: {
      options = {
        enable = mkEnableOption (mdDoc "Vault Agent instance");
        name = mkOption {
          type = types.str;
          default = name;
          description = mdDoc ''
            Name is used as a prefix for the service name.
            By default it takes the value you use for `<instance>` in:
            {option}`services.vault-agent.instances.<instance>`
          '';
        };
        package = mkPackageOption pkgs "Vault" { default = "vault"; };
        roleId = mkOption {
          example = "11111111-2222-3333-4444-555555555555";
          type = types.str;
        };
        secretIdFile = mkOption {
          example = "/run/agenix/example-approle-secret-id";
          type = types.str;
        };
        templates = mkOption {
          default = [ ];
          type = types.listOf (types.attrs);
        };
        owner = mkOption {
          default = "root";
          type = types.str;
        };
        group = mkOption {
          default = "wheel";
          type = types.str;
        };
      };
    };
in
{
  # Apparently there's a new module for this in nixpkgs-unstable, but it's not as opinionated as
  # mine, and doesn't really provide enough to be worth building on top of.
  disabledModules = [ "services/security/vault-agent.nix" ];

  options.services.vault-agent.instances = with lib;
    mkOption {
      default = { };
      type = types.attrsOf (types.submodule vaultAgentOpts);
    };

  config =
    let
      mkInstanceServiceConfig = instance:
        let
          format = pkgs.formats.json { };
          roleIdFile = pkgs.writeText "${instance.name}-role-id" instance.roleId;
          configFile = format.generate "vault-agent.json" {
            vault.address = "http://vault.service.consul:8200";
            auto_auth.method = [
              {
                type = "approle";
                config = {
                  remove_secret_id_file_after_reading = false;
                  role_id_file_path = "${roleIdFile}";
                  secret_id_file_path = instance.secretIdFile;
                };
              }
            ];
            template = instance.templates;
          };
        in
        {
          description = "Vault Agent - ${instance.name}";

          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          path = [ pkgs.glibc ];

          startLimitIntervalSec = 60;
          startLimitBurst = 3;
          serviceConfig = {
            ExecStart = "${instance.package}/bin/vault agent -config=${configFile}";
            ExecReload = "${pkgs.coreutils}/bin/kill -SIGHUP $MAINPID";
            PrivateDevices = true;
            PrivateTmp = true;
            ProtectHome = "read-only";
            NoNewPrivileges = true;
            KillSignal = "SIGINT";
            TimeoutStopSec = "30s";
            Restart = "on-failure";
          };
        };
      instances = lib.attrValues cfg.instances;
    in
    {
      systemd.tmpfiles.rules =
        map (instance: "d ${instance.secretsPath} 0700 ${instance.owner} ${instance.group} - -")
          instances;

      systemd.services =
        lib.mkMerge
          (map
            (instance:
              lib.mkIf instance.enable {
                "${instance.name}-vault-agent" = mkInstanceServiceConfig instance;
              })
            instances);
    };
}
