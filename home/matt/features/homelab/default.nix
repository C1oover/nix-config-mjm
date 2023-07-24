{
  pkgs,
  inputs,
  config,
  ...
}: let
  updateYubikeyCert = pkgs.writeShellScriptBin "update-yubikey-cert" ''
    ${pkgs.vault}/bin/vault ssh \
      -mode="ca" \
      -role="homelab-client" \
      -mount-point="ssh-client-signer" \
      -public-key-path="${config.home.homeDirectory}/.ssh/yubikey.pub" \
      -valid-principals="matt" \
      -no-exec \
      -field=signed_key \
      "$1" \
      >"${config.home.homeDirectory}/.ssh/yubikey-cert.pub"
  '';

  vssh = pkgs.writeShellScriptBin "vssh" ''
    ${updateYubikeyCert}/bin/update-yubikey-cert
    ssh -i "${config.home.homeDirectory}/.ssh/yubikey-cert.pub" "$@"
  '';

  tmssh = pkgs.writeShellScriptBin "tmssh" ''
    ${vssh}/bin/vssh "$@" -t 'tmux -CC new -A -s tmssh'
  '';

  s = pkgs.writeShellScriptBin "s" ''
    ${updateYubikeyCert}/bin/update-yubikey-cert
    ${pkgs.kitty}/bin/kitty +kitten ssh -i "${config.home.homeDirectory}/.ssh/yubikey-cert.pub" "$@"
  '';

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
      IdentityFile = "~/.ssh/yubikey.pub";
    };
  };
}
