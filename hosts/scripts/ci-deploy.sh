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

# deploy to hypnos first, because it may need to reload the gitlab-runner, which fails if
# the ingress is unavailable, which might temporarily happen when deploying to the other
# hosts.
colmena apply --on hypnos --keep-result

colmena apply --on "@x86_64,arges" --keep-result

# deploy to ingress last, since it can disrupt the build
colmena apply --on "@ingress" --keep-result

attic push homelab .gcroots/node-*
