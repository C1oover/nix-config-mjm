set -o errexit
set -o nounset
set -o pipefail

jj new "$(,jf "$@")"
