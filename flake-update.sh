function latest_nixpkgs() {
  name="$1"
  curl -s "https://monitoring.nixos.org/prometheus/api/v1/query?query=channel_revision%7Bchannel%3D%22$name%22%7D" |
    jq -r '.data.result[0].metric.revision'
}

function my_nixpkgs() {
  name="$1"
  nixpkgs_name="$(nix flake metadata . --json | jq -r ".locks.nodes.root.inputs.$name")"
  nix flake metadata . --json | jq -r ".locks.nodes.$nixpkgs_name.locked.rev"
}

function is_current() {
  channel_name="$1"
  input_name="$2"

  latest="$(latest_nixpkgs "$channel_name")"
  mine="$(my_nixpkgs "$input_name")"

  echo "checking $channel_name:"
  echo "latest = $latest"
  echo "mine   = $mine"
  echo

  [ "$latest" = "$mine" ]
}

if is_current nixpkgs-unstable nixpkgs && is_current nixos-unstable nixos; then
  echo "no updates: all done"
  exit 0
fi

echo "latest nixpkgs doesn't match my version. updating flake inputs..."
nix flake update
git config user.email "gitlab@matt.mattmoriarity.com"
git config user.name "GitLab Automation"
git add flake.lock
git commit -m "nix flake update"
git remote add gitlab "https://ci:$FLAKE_UPDATE_TOKEN@$CI_SERVER_HOST/$CI_PROJECT_PATH.git"
git push gitlab HEAD:main
