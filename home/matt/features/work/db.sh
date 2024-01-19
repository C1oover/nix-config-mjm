set -o errexit
set -o nounset
set -o pipefail

preset="$1"

case "$preset" in
*-replica)
  user=teleport-ro
  name="slab-sql-$preset-pg14-0"
  ;;
*)
  user=teleport-rw
  name="slab-sql-$preset-pg14"
  ;;
esac

case "$preset" in
prod*)
  iam_host=slab-prod.iam
  ;;
stage*)
  iam_host=slab-stage.iam
  ;;
esac

tsh -k no proxy db "--db-user=$user@$iam_host" --db-name=slab --tunnel --port 5432 "$name"
