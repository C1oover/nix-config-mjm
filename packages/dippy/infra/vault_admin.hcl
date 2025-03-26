# read system health check
path "sys/health" {
  capabilities = ["read", "sudo"]
}

# create and manage acl policies
path "sys/policies/acl" {
  capabilities = ["list"]
}
path "sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# enable and manage auth methods
path "auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
path "sys/auth" {
  capabilities = ["read"]
}
path "sys/auth/*" {
  capabilities = ["create", "update", "delete", "sudo"]
}

# manage secrets engines
path "sys/mounts" {
  capabilities = ["read"]
}
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "sys/plugins/catalog/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
path "sys/leases/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "kv/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
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
