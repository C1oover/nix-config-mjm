set -o errexit
set -o nounset
set -o pipefail

source functions.sh

ci_vault_login
create_temp_key

config_file="$SSH_KEY_DIR/ssh_config"
cat >"$config_file" <<EOF
IdentityFile $SSH_KEY_PATH
EOF
export SSH_CONFIG_FILE="$config_file"

colmena apply --on "@phase-main" --keep-result
# deploy to ingress last, since it can disrupt the build
colmena apply --on "@phase-ingress" --keep-result

attic push homelab .gcroots/node-*
