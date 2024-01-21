set -o errexit
set -o nounset
set -o pipefail

source functions.sh

ci_vault_login

ATTIC_TOKEN=$(vault kv get -field=token kv/attic/client)
attic login --set-default homelab https://attic.midna.dev "$ATTIC_TOKEN"

# ensure attic itself gets cached, since it's expensive to build
attic push homelab "$ATTIC"
