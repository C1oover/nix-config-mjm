path "sys/leader" {
  capabilities = ["read"]
}

path "sys/storage/raft/snapshot" {
  capabilities = ["read"]
}
