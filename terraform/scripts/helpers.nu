export def link-tf-config [] {
  ln -sf $env.TF_CONFIG terraform/config.tf.json
}

export def tofu [...args] {
  cd terraform
  ^tofu ...$args
}

export def with-vault [block] {
  let token = vault write -field=token auth/gitlab/login role=homelab-infra $"jwt=($env.VAULT_ID_TOKEN)"
  with-env {VAULT_TOKEN: $token} $block
}
