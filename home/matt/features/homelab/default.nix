{
  pkgs,
  config,
  osConfig,
  ...
}:
let
  useYubikey = if pkgs.stdenv.isLinux then osConfig.services.yubikey-agent.enable else true;

  sshPublicKeyName = if useYubikey then "yubikey.pub" else "id_ed25519.pub";
  sshPublicKeyPath = "${config.home.homeDirectory}/.ssh/${sshPublicKeyName}";

  envVars = {
    CONSUL_HTTP_ADDR = "http://consul.service.consul:8500";
    VAULT_ADDR = "http://vault.service.consul:8200";
  };
in
{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      consul
      minio-client
      tarsnap
      vault
      wander
      ;

    homelab = pkgs.callPackage ./scripts.nix { inherit sshPublicKeyPath; };
  };

  home.sessionVariables = envVars;

  programs.nushell.shellAliases = {
    ",s" = "homelab ssh kitty";
    ",vssh" = "homelab ssh vault";
  };

  programs.ssh = {
    enable = true;
    extraOptionOverrides = {
      IdentityFile =
        if useYubikey then sshPublicKeyPath else builtins.replaceStrings [ ".pub" ] [ "" ] sshPublicKeyPath;
    };
  };
}
