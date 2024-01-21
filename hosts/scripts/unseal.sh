set -o errexit
set -o nounset
set -o pipefail

host="$1"
export VAULT_ADDR="http://$host:8200"

vault operator unseal "$(op read "op://Private/Homelab Vault Keys/Unseal Keys/638880CCF1664DED95BB219A708A896A")"
vault operator unseal "$(op read "op://Private/Homelab Vault Keys/Unseal Keys/979343926DF44A88B93808C49CE2FE26")"
vault operator unseal "$(op read "op://Private/Homelab Vault Keys/Unseal Keys/368F61C90CD34E2BBDF03F02C314AA1D")"
