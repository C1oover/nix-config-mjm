set -euo pipefail

sudo -H --preserve-env=PATH env nix-env -p /nix/var/nix/profiles/system --set "$(readlink -f result)"
"$PWD/result/activate-user"
sudo -H --preserve-env=PATH ./result/activate
