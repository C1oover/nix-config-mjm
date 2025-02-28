{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.server;
in
{
  config = mkIf (cfg.enable && cfg.enableSSHHostCert) {
    vault.policies.common-host = {
      paths."ssh-host-signer/sign/homelab-host".capabilities = [ "update" ];
    };
    vault-secrets.wantedBy = [ "sshd.service" ];
    vault-secrets.templates.ssh-host-cert = {
      text = ''
        {{ with secret "ssh-host-signer/sign/homelab-host" "cert_type=host" (printf "public_key=%s" (file "/etc/ssh/ssh_host_ed25519_key.pub")) "valid_principals=${config.networking.hostName}.home.mattmoriarity.com" }}
        {{ .Data.signed_key }}
        {{ end }}
      '';
      mode = "0640";
    };

    services.openssh.settings.HostCertificate = config.vault-secrets.templates.ssh-host-cert.path;

    # If vault is not available when the machine starts, then rendering vault secrets may
    # fail, causing the host certificate to not be present when sshd starts. It's not great
    # to block sshd from start because of this, as it might be the only way to easily
    # access the machine, so let's at least detect the situation and alert on it.
    services.consul.services.sshd = {
      port = 22;

      checks.host-cert = {
        name = "sshd host certificate is being used";
        script.args =
          let
            script = pkgs.writeScript "ssh-host-cert-check" ''
              #!/bin/sh
              ${pkgs.openssh}/bin/ssh-keyscan -c ${config.networking.hostName}.home.mattmoriarity.com || exit 2
            '';
          in
          [ "${script}" ];
        intervalSeconds = 30;
      };
    };

    # In case sshd starts without a host certificate, perhaps because vault is unavailable,
    # watch the path to the cert and trigger a restart when it shows up.
    systemd.paths.ssh-host-cert = {
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathChanged = "/run/vault-secrets/ssh-host-cert";
    };
    systemd.services.ssh-host-cert = {
      after = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl restart sshd.service";
      };
    };
  };
}
