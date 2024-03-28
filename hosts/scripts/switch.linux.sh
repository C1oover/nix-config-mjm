set -euo pipefail

ACTION=${1:-switch}

sudo nix-env -p /nix/var/nix/profiles/system --set "$(readlink -f result)"
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
  ./result/bin/switch-to-configuration \
  "$ACTION"
