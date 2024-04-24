set -euo pipefail

nom-build hosts/darwin.nix -A "$(scutil --get LocalHostName).system" "$@"
nvd diff /run/current-system ./result
