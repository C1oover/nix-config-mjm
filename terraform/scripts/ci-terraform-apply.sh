set -o errexit
set -o nounset
set -o pipefail

source functions.sh

VAULT_TOKEN=$(vault write -field=token auth/gitlab/login role=homelab-infra "jwt=$VAULT_ID_TOKEN")
export VAULT_TOKEN

link_tf_config
tofu init
tofu apply -auto-approve
