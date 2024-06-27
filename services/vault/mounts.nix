{ config, lib, ... }:
let
  inherit (lib) mkIf;
in
{
  config = mkIf config.mjm.vault.enable {
    terraform.resource.vault_mount.kv = {
      path = "kv";
      type = "kv";
      options = {
        version = "2";
      };
    };

    terraform.resource.vault_mount.ssh_client_signer = {
      type = "ssh";
      path = "ssh-client-signer";
    };

    terraform.resource.vault_ssh_secret_backend_role.homelab_client = {
      name = "homelab-client";
      backend = "\${vault_mount.ssh_client_signer.path}";
      key_type = "ca";
      ttl = 2 * 60 * 60;
      default_user = "matt";
      default_extensions.permit-pty = "";
      allowed_extensions = "permit-agent-forwarding,permit-port-forwarding,permit-pty,permit-user-rc,permit-X11-forwarding";
      allow_user_certificates = true;
      allowed_users = "*";
    };

    terraform.resource.vault_mount.ssh_host_signer = {
      type = "ssh";
      path = "ssh-host-signer";

      max_lease_ttl_seconds = 315360000;
    };

    terraform.resource.vault_ssh_secret_backend_role.homelab_host = {
      name = "homelab-host";
      backend = "\${vault_mount.ssh_host_signer.path}";
      key_type = "ca";
      algorithm_signer = "default";
      allow_host_certificates = true;
      allow_bare_domains = true;
      allow_subdomains = true;
      allowed_domains = "home.mattmoriarity.com";
      ttl = 10 * 365 * 24 * 60 * 60;
    };
  };
}
