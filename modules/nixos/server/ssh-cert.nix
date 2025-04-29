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
    services.openssh.settings.HostCertificate = "/run/sshd-host-cert/cert";

    systemd.services.sshd-host-cert = {
      wantedBy = [ "multi-user.target" ];
      before = [ "sshd.service" ];
      after = [
        "network-online.target"
        "spire-agent.service"
      ];
      wants = [ "network-online.target" ];
      path = with pkgs; [
        vault
        glibc.getent
        spire-agent
        jq
        coreutils
        systemd
      ];
      preStart = ''
        # wait a bit for the spire-agent socket to be available
        for ((i=0; i<5; i++)); do
          [ -S ${config.mjm.spire.agent.socketPath} ] && break
          sleep 2
        done

        spire-agent api fetch -socketPath ${config.mjm.spire.agent.socketPath} -write /run/sshd-host-cert
      '';
      script = ''
        jwt="$(spire-agent api fetch jwt -audience $VAULT_ADDR -output json -socketPath ${config.mjm.spire.agent.socketPath} | jq -r '.[0].svids[0].svid')"
        export VAULT_TOKEN=placeholder
        VAULT_TOKEN="$(vault write -field=token auth/spiffe/login role=spiffe jwt=$jwt)"
        export VAULT_TOKEN

        vault write \
          -field=signed_key \
          ssh-host-signer/sign/homelab-host \
          cert_type=host \
          public_key=@/etc/ssh/ssh_host_ed25519_key.pub \
          valid_principals=${config.networking.hostName}.home.mattmoriarity.com \
          >/run/sshd-host-cert/cert

        # important to not block here, as it seems that this restart, presumably because of the dependencies between
        # sshd.service and this unit, will block forever without --no-block
        systemctl --no-block try-restart sshd.service
      '';
      environment = {
        VAULT_ADDR = "https://vault.service.consul:8200";
        VAULT_CACERT = "/run/sshd-host-cert/bundle.0.pem";
      };
      startLimitIntervalSec = 0;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = "5s";
        RuntimeDirectory = "sshd-host-cert";

        CapabilityBoundingSet = "";
        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        PrivateDevices = true;
        PrivateIPC = true;
        PrivateUsers = "identity";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = "read-only";
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
        SystemCallErrorNumber = "EPERM";
        SystemCallFilter = [
          "@system-service"
          "~@resources @privileged"
        ];
        UMask = "0027";
      };
    };

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
  };
}
