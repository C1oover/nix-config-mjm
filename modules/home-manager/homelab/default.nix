{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.mjm.homelab;
  envVars = {
    CONSUL_HTTP_ADDR = "http://consul.service.consul:8500";
    VAULT_ADDR = "https://vault.midna.dev";
  };

  updateCert = pkgs.writeShellScript "update-ssh-cert" ''
    cert=$(${lib.getExe pkgs.vault} write -field=signed_key ssh-client-signer/sign/homelab-client public_key=@${cfg.sshPublicKeyPath})
    if [ $? -eq 0 ]; then
      echo $cert > ${cfg.sshCertPath}
    fi
  '';
in
{
  options.mjm.homelab = {
    enable = mkEnableOption "homelab client tools";

    enableSecretive = mkOption {
      type = types.bool;
      default = pkgs.stdenv.isDarwin;
    };

    sshPublicKeyName = mkOption {
      type = types.str;
      default = "id_ed25519.pub";
    };

    sshPublicKeyDir = mkOption {
      type = types.path;
      default =
        if cfg.enableSecretive then
          "${config.home.homeDirectory}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/PublicKeys"
        else
          "${config.home.homeDirectory}/.ssh";
    };

    sshPublicKeyPath = mkOption {
      type = types.path;
      default = "${cfg.sshPublicKeyDir}/${cfg.sshPublicKeyName}";
    };

    sshPrivateKeyPath = mkOption {
      type = types.path;
      default = builtins.replaceStrings [ ".pub" ] [ "" ] cfg.sshPublicKeyPath;
    };

    sshCertPath = mkOption {
      type = types.path;
      default = "${config.home.homeDirectory}/.ssh/${
        builtins.replaceStrings [ ".pub" ] [ "-cert.pub" ] cfg.sshPublicKeyName
      }";
    };
  };

  config = mkIf cfg.enable {
    home.packages = builtins.attrValues {
      inherit (pkgs)
        consul
        minio-client
        vault
        ;
    };

    home.sessionVariables = envVars;

    programs.ssh = {
      enable = true;
      extraOptionOverrides.IdentityFile = mkIf (!cfg.enableSecretive) (
        builtins.replaceStrings [ ".pub" ] [ "" ] cfg.sshPublicKeyPath
      );
      extraOptionOverrides.IdentityAgent = mkIf cfg.enableSecretive "${config.home.homeDirectory}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
      matchBlocks.homelab = {
        match = "host *.home.mattmoriarity.com exec \"${updateCert}\"";
        identityFile = cfg.sshPublicKeyPath;
        certificateFile = cfg.sshCertPath;
      };
    };
  };
}
