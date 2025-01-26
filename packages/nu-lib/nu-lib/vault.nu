export def with-vault [block] {
  let token =  if ($env.VAULT_ID_TOKEN? | is-empty) {
    vault read -field=id auth/token/lookup
  } else {
    vault write -field=token auth/gitlab/login role=homelab-infra $"jwt=($env.VAULT_ID_TOKEN)"
  }

  with-env {VAULT_TOKEN: $token} $block
}
