{
  terraform.resource.vault_mount.kv = {
    path = "kv";
    type = "kv";
    options = {
      version = "2";
    };
  };
}
