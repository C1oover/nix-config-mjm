set -o errexit
set -o nounset
set -o pipefail

source functions.sh

colmena build --on "@phase-main,@phase-ingress" --keep-result

push_to_attic() {
  attic push homelab .gcroots/node-*
}

retry 5 push_to_attic
