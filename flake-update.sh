function latest_nixpkgs() {
  curl -s 'https://monitoring.nixos.org/prometheus/api/v1/query?query=channel_revision%7Bchannel%3D%22nixpkgs-unstable%22%7D' \
    | jq -r '.data.result[0].metric.revision'
}

function my_nixpkgs() {
  nixpkgs_name="$(nix flake metadata . --json | jq -r '.locks.nodes.root.inputs.nixpkgs')"
  nix flake metadata . --json | jq -r ".locks.nodes.$nixpkgs_name.locked.rev"
}

latest="$(latest_nixpkgs)"
mine="$(my_nixpkgs)"
echo "latest: $latest"
echo "mine: $mine"

if [ "$latest" = "$mine" ]; then
  echo "no updates: all done"
  exit 0
fi

echo "latest nixpkgs doesn't match my version. updating..."
nix flake update
git config user.email "gitlab@matt.mattmoriarity.com"
git config user.name "GitLab Automation"
git add flake.lock
git commit -m "nix flake update"
git remote add gitlab "https://ci:$FLAKE_UPDATE_TOKEN@$CI_SERVER_HOST/$CI_PROJECT_PATH.git"
git push gitlab HEAD:main
