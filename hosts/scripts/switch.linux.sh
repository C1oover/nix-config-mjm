set -euo pipefail

ACTION=${1:-switch}
BUILT_SYSTEM="./.gcroots/node-$(hostname)"

sudo nix-env -p /nix/var/nix/profiles/system --set "$(readlink -f "$BUILT_SYSTEM")"
sudo systemd-run \
  -E LOCALE_ARCHIVE \
  --collect \
  --no-ask-password \
  --pty \
  --quiet \
  --same-dir \
  --service-type=exec \
  --unit=nixos-rebuild-switch-to-configuration \
  --wait \
  "$BUILT_SYSTEM/bin/switch-to-configuration" \
  "$ACTION"
