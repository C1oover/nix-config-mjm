{
  vault.approles.roles.teamcity = {};

  vault.policies.teamcity.text = ''
    path "ssh-client-signer/sign/homelab-client" {
      capabilities = ["update"]
    }

    # Allow reading the Ansible vault password
    path "kv/data/deploy" {
      capabilities = ["read"]
    }

    # Allow issuing client certs for accessing the Nomad API over mTLS
    path "pki-int/issue/nomad-cluster" {
      capabilities = ["update"]
    }

    # Allow submitting jobs to Nomad
    path "nomad/creds/deploy" {
      capabilities = ["read"]
    }

    # Allow updating Vault policies for apps
    path "sys/policies/acl/*" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }
  '';
}
