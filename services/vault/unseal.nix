{
  pkgs,
  lib,
  utils,
  config,
  ...
}:
let
  inherit (lib)
    concatImapStringsSep
    imap
    mkIf
    mkOption
    replaceStrings
    types
    ;
  cfg = config.mjm.vault;

  pkg = pkgs.vault-unseal;

  unsealCfg = builtins.toJSON {
    unseal_tokens = imap (i: _: "$TOKEN${toString i}") cfg.encryptedUnsealTokens;
  };
in
{
  options.mjm.vault = {
    encryptedUnsealTokens = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    systemd.services.vault-unseal = {
      description = "Automatically Unseal Vault";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      preStart = ''
        ${concatImapStringsSep "\n" (
          i: _: "TOKEN${toString i}=$(cat $CREDENTIALS_DIRECTORY/token${toString i})"
        ) cfg.encryptedUnsealTokens}
        echo "${replaceStrings [ "\"" ] [ "\\\"" ] unsealCfg}" > $RUNTIME_DIRECTORY/config
      '';
      serviceConfig = {
        ExecStart = utils.escapeSystemdExecArgs (
          [
            (lib.getExe pkg)
            "--environment=prod"
            # TODO fix this by giving this a spiffe bundle for the CA
            "--tls-skip-verify"
            "--config=/run/vault-unseal/config"
          ]
          ++ (map (n: "--nodes=https://${n}:8200") cfg.nodes)
        );
        LoadCredentialEncrypted = imap (
          i: token: "token${toString i}:${pkgs.writeText "unseal-token-${toString i}" token}"
        ) cfg.encryptedUnsealTokens;
        Restart = "always";
        DynamicUser = true;
        RuntimeDirectory = "vault-unseal";
        CapabilityBoundingSet = [ "" ];
        DeviceAllow = [ "" ];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        UMask = "0077";
      };
    };
  };
}
