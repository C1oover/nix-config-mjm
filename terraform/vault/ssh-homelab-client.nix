{
  resource.vault_mount.ssh_client_signer = {
    type = "ssh";
    path = "ssh-client-signer";
  };

  resource.vault_ssh_secret_backend_role.homelab_client = {
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
}
