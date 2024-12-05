export def with-vault [block] {
  if ($env.VAULT_ID_TOKEN? | is-empty) {
    print -e "skipping setting vault token"
    do $block
  } else {
    let token = vault write -field=token auth/gitlab/login role=homelab-infra $"jwt=($env.VAULT_ID_TOKEN)"
    with-env {VAULT_TOKEN: $token} $block
  }
}
