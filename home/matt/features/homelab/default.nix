{
  pkgs,
  inputs,
  config,
  osConfig,
  ...
}:
let
  useYubikey = if pkgs.stdenv.isLinux then osConfig.services.yubikey-agent.enable else true;

  sshPublicKeyName = if useYubikey then "yubikey.pub" else "id_ed25519.pub";
  sshPublicKeyPath = "${config.home.homeDirectory}/.ssh/${sshPublicKeyName}";

  envVars = {
    NOMAD_ADDR = "http://nomad.service.consul:4646";
    CONSUL_HTTP_ADDR = "http://consul.service.consul:8500";
    VAULT_ADDR = "http://vault.service.consul:8200";
  };

  # nomad 1.5 isn't building correctly on macOS rn
  nomad = if pkgs.stdenv.isLinux then pkgs.nomad else pkgs.nomad_1_4;
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

    inherit nomad;

    devenv = inputs.devenv.packages.${pkgs.system}.default;

    inherit (pkgs.callPackages ./scripts.nix { inherit sshPublicKeyPath; }) s vssh;
  };

  home.sessionVariables = envVars;

  programs.ssh = {
    enable = true;
    extraOptionOverrides = {
      IdentityFile =
        if useYubikey then sshPublicKeyPath else builtins.replaceStrings [ ".pub" ] [ "" ] sshPublicKeyPath;
    };
  };
}
