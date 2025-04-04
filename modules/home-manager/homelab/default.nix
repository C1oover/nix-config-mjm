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

  sshPublicKeyPath = "${config.home.homeDirectory}/.ssh/${cfg.sshPublicKeyName}";

  envVars = {
    CONSUL_HTTP_ADDR = "http://consul.service.consul:8500";
    VAULT_ADDR = "https://vault.midna.dev";
  };
in
{
  options.mjm.homelab = {
    enable = mkEnableOption "homelab client tools";

    enableYubikey = mkOption {
      type = types.bool;
      default = false;
    };

    sshPublicKeyName = mkOption {
      type = types.str;
      default = if cfg.enableYubikey then "yubikey.pub" else "id_ed25519.pub";
    };
  };

  config = mkIf cfg.enable {
    home.packages = builtins.attrValues {
      inherit (pkgs)
        consul
        minio-client
        vault
        ;

      homelab = pkgs.callPackage ./scripts.nix { inherit sshPublicKeyPath; };
    };

    home.sessionVariables = envVars;

    programs.fish.shellAliases.",s" = "homelab ssh vault";
    programs.nushell.shellAliases = {
      ",s" = "homelab ssh kitty";
      ",vssh" = "homelab ssh vault";
    };

    programs.ssh = {
      enable = true;
      extraOptionOverrides = {
        IdentityFile =
          if cfg.enableYubikey then
            sshPublicKeyPath
          else
            builtins.replaceStrings [ ".pub" ] [ "" ] sshPublicKeyPath;
      };
    };
  };
}
