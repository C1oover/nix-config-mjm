ci_vault_login() {
  VAULT_TOKEN=$(vault write -field=token auth/gitlab/login role=homelab-infra "jwt=$VAULT_ID_TOKEN")
  export VAULT_TOKEN
}

create_temp_key() {
  SSH_KEY_DIR=$(mktemp -d)
  SSH_KEY_PATH="$SSH_KEY_DIR/id_ed25519"

  ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N ""

  vault write \
    -field=signed_key \
    ssh-client-signer/sign/homelab-client \
    "public_key=@$SSH_KEY_PATH.pub" \
    valid_principals=matt \
    >"$SSH_KEY_PATH-cert.pub"

  trap remove_temp_key EXIT
}

remove_temp_key() {
  echo "Removing temp directory ${SSH_KEY_DIR}" >&2
  rm -rf "$SSH_KEY_DIR"
}

retry() {
  local retries="$1"
  shift
  local options="$-"

  if [[ $options == *e* ]]; then
    set +e
  fi

  "$@"
  local exit_code=$?

  if [[ $options == *e* ]]; then
    set -e
  fi

  if [[ $exit_code -ne 0 && $retries -gt 0 ]]; then
    sleep 3
    retry $((retries - 1)) "$@"
  else
    return $exit_code
  fi
}
