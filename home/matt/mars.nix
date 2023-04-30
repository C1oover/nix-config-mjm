{ config
, pkgs
, inputs
, ...
}:
let
  vssh = pkgs.writeShellScriptBin "vssh" ''
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

    ssh -i "${config.home.homeDirectory}/.ssh/yubikey-cert.pub" "$@"
  '';

  tmssh = pkgs.writeShellScriptBin "tmssh" ''
    ${vssh}/bin/vssh "$@" -t 'tmux -CC new -A -s tmssh'
  '';

  devenv = inputs.devenv.packages.x86_64-darwin.default;
in
{
  imports = [
    ./global
    ./global/darwin.nix
  ];

  home.packages = with pkgs; [
    consul
    devenv
    minio-client
    nomad
    tarsnap
    vault

    vssh
    tmssh
  ];

  home.sessionVariables = {
    NOMAD_ADDR = "http://nomad.service.consul:4646";
    CONSUL_HTTP_ADDR = "http://consul.service.consul:8500";
    VAULT_ADDR = "http://vault.service.consul:8200";
  };

  home.dock = {
    enable = true;
    entries = [
      { path = "/System/Applications/Mail.app/"; }
      { path = "/Applications/Firefox.app/"; }
      { path = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/"; }
      { path = "/System/Applications/Messages.app/"; }
      { path = "/System/Applications/Maps.app/"; }
      { path = "/Applications/Fantastical.app/"; }
      { path = "/System/Applications/System Settings.app/"; }
      { path = "/Applications/1Password.app/"; }
      { path = "/Applications/Drafts.app/"; }
      { path = "${pkgs.iterm2}/Applications/iTerm2.app/"; }
      { path = "/Applications/Dash.app/"; }
      { path = "/Applications/Slab.app/"; }
      { path = "${pkgs.slack}/Applications/Slack.app/"; }
      { path = "${pkgs.discord}/Applications/Discord.app/"; }
      {
        path = "${config.home.homeDirectory}/Downloads/";
        section = "others";
        options = "--sort dateadded --view grid --display folder";
      }
    ];
  };

  programs.ssh = {
    enable = true;
    extraOptionOverrides = {
      IdentityFile = "~/.ssh/yubikey.pub";
    };
    matchBlocks = {
      "nas" = {
        host = "nas";
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };
}
