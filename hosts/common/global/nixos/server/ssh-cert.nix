{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.server;
in
{
  config = mkIf (cfg.enable && cfg.enableSSHHostCert) {
    vault-secrets.templates.ssh-host-cert = {
      text = ''
        {{ with secret "ssh-host-signer/sign/homelab-host" "cert_type=host" (printf "public_key=%s" (file "/etc/ssh/ssh_host_ed25519_key.pub")) "valid_principals=${config.networking.hostName}.home.mattmoriarity.com" }}
        {{ .Data.signed_key }}
        {{ end }}
      '';
      mode = "0640";
    };

    services.openssh.settings.HostCertificate = config.vault-secrets.templates.ssh-host-cert.path;
  };
}
