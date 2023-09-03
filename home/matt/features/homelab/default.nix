{
  pkgs,
  inputs,
  config,
  osConfig,
  ...
}: let
  useYubikey =
    if pkgs.stdenv.isLinux
    then osConfig.services.yubikey-agent.enable
    else true;

  sshPublicKeyName =
    if useYubikey
    then "yubikey.pub"
    else "id_ed25519.pub";
  sshPublicKeyPath = "${config.home.homeDirectory}/.ssh/${sshPublicKeyName}";
  sshCertPath = builtins.replaceStrings [".pub"] ["-cert.pub"] sshPublicKeyPath;

  updateSshCert = pkgs.writeShellApplication {
    name = "update-ssh-cert";
    runtimeInputs = [pkgs.vault];
    text = ''
      vault write \
        -field=signed_key \
        ssh-client-signer/sign/homelab-client \
        public_key=@${sshPublicKeyPath} \
        valid_principals=matt \
        >"${sshCertPath}"
    '';
  };

  vssh = pkgs.writeShellApplication {
    name = "vssh";
    runtimeInputs = [pkgs.openssh updateSshCert];
    text = ''
      update-ssh-cert
      ssh -i "${sshCertPath}" "$@"
    '';
  };

  tmssh = pkgs.writeShellApplication {
    name = "tmssh";
    runtimeInputs = [vssh];
    text = ''
      vssh "$@" -t 'tmux -CC new -A -s tmssh'
    '';
  };

  s = pkgs.writeShellApplication {
    name = "s";
    runtimeInputs = [updateSshCert pkgs.kitty];
    text = ''
      update-ssh-cert
      kitty +kitten ssh -i "${sshCertPath}" "$@"
    '';
  };

  devenv = inputs.devenv.packages.${pkgs.system}.default;

  envVars = {
    NOMAD_ADDR = "http://nomad.service.consul:4646";
    CONSUL_HTTP_ADDR = "http://consul.service.consul:8500";
    VAULT_ADDR = "http://vault.service.consul:8200";
  };

  # nomad 1.5 isn't building correctly on macOS rn
  nomad =
    if pkgs.stdenv.isLinux
    then pkgs.nomad
    else pkgs.nomad_1_4;
in {
  home.packages = with pkgs; [
    consul
    devenv
    minio-client
    nomad
    tarsnap
    vault
    wander

    s
    vssh
    tmssh
  ];

  home.sessionVariables = envVars;

  programs.ssh = {
    enable = true;
    extraOptionOverrides = {
      IdentityFile =
        if useYubikey
        then sshPublicKeyPath
        else builtins.replaceStrings [".pub"] [""] sshPublicKeyPath;
    };
  };
}
