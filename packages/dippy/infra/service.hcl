path "kv/data/prod/services/{{identity.entity.metadata.service}}" {
  capabilities = ["read"]
}

path "kv/data/prod/services/{{identity.entity.metadata.service}}/*" {
  capabilities = ["read"]
}
