{
  config,
  pkgs,
  inputs,
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

  devenv = inputs.devenv.packages.x86_64-darwin.default;
in {
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

    s
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
      {path = "/System/Applications/Mail.app/";}
      {path = "${pkgs.firefox-bin}/Applications/Firefox.app/";}
      {path = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/";}
      {path = "/System/Applications/Messages.app/";}
      {path = "/System/Applications/Maps.app/";}
      {path = "/Applications/Fantastical.app/";}
      {path = "/System/Applications/System Settings.app/";}
      {path = "/Applications/1Password.app/";}
      {path = "/Applications/Drafts.app/";}
      {path = "${pkgs.kitty}/Applications/kitty.app/";}
      {path = "/Applications/Dash.app/";}
      {path = "/Applications/Slab.app/";}
      {path = "${pkgs.slack}/Applications/Slack.app/";}
      {path = "${pkgs.discord}/Applications/Discord.app/";}
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

  programs.kitty.settings = {
    hide_window_decorations = "titlebar-only";
    focus_follows_mouse = "yes";
  };

  programs.mr = {
    settings = {
      "Projects/bastille-templates" = {
        checkout = "git clone https://gitlab.home.mattmoriarity.com/mjm/bastille-templates.git";
      };
      "Projects/dark_vader" = {
        checkout = "git clone https://gitlab.home.mattmoriarity.com/mjm/dark-vader.git";
      };
      "Projects/homelab" = {
        checkout = "git clone https://gitlab.home.mattmoriarity.com/mjm/homelab.git";
      };
      "Projects/homelab-infra" = {
        checkout = "git clone https://gitlab.home.mattmoriarity.com/mjm/homelab-infra.git";
      };
      "Projects/nix-config" = {
        checkout = "git clone https://gitlab.home.mattmoriarity.com/mjm/nix-config.git";
      };
    };
  };
}
