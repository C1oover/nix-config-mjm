set -o errexit
set -o nounset
set -o pipefail

source functions.sh

ci_vault_login

ATTIC_TOKEN=$(vault kv get -field=attic_token kv/prod/repos/nix-config)
attic login --set-default homelab https://attic.midna.dev "$ATTIC_TOKEN"
