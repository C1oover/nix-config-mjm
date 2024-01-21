set -o errexit
set -o nounset
set -o pipefail

source functions.sh

link_tf_config
tofu init
tofu apply "$@"
