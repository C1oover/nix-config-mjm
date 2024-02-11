set -o errexit
set -o nounset
set -o pipefail

host="$1"
export VAULT_ADDR="http://$host:8200"

vault operator unseal "$(rbw get "Homelab Vault Keys" --field "Unseal Key 1")"
vault operator unseal "$(rbw get "Homelab Vault Keys" --field "Unseal Key 2")"
vault operator unseal "$(rbw get "Homelab Vault Keys" --field "Unseal Key 3")"
