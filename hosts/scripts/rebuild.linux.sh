set -euo pipefail

colmena build --on "$(hostname)" --keep-result -v "$@"
nvd diff /run/current-system "./.gcroots/node-$(hostname)"
