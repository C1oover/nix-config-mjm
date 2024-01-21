set -o errexit
set -o nounset
set -o pipefail

source functions.sh

create_temp_key

config_file="$SSH_KEY_DIR/ssh_config"
cat >"$config_file" <<EOF
IdentityFile $SSH_KEY_PATH
Host *
  UserKnownHostsFile ~/.ssh/known_hosts
EOF

export SSH_CONFIG_FILE="$config_file"
colmena apply "$@"
