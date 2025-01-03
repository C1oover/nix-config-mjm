set -o errexit
set -o nounset
set -o pipefail

jj log --no-graph --color never -T 'change_id ++ " " ++ description.first_line() ++ "\n"' "$@" |
  fzf --with-nth 2.. |
  cut -d' ' -f1
