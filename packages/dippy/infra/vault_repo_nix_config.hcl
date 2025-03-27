# read kv secrets used in builds for the repo
path "kv/data/prod/repos/nix-config" {
  capabilities = ["read"]
}

# issue ssh certs for deploying to machines
path "ssh-client-signer/sign/homelab-client" {
  capabilities = ["update"]
}

# apply infrastructure changes
path "sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
path "auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
path "sys/auth" {
  capabilities = ["read"]
}
path "sys/auth/*" {
  capabilities = ["create", "update", "delete", "sudo"]
}
path "sys/mounts" {
  capabilities = ["read"]
}
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
path "kv/*" {
  capabilities = ["create", "read", "update", "delete"]
}
path "ssh-client-signer/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
path "ssh-host-signer/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
path "identity/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
