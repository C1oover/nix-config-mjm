function latest_nixpkgs() {
  name="$1"
  curl --head --silent --write-out "%{redirect_url}\n" --output /dev/null \
    "https://channels.nixos.org/$name/nixexprs.tar.xz"
}

function my_nixpkgs() {
  name="$1"
  jq <npins/sources.json -r ".pins.$name.url"
}

function is_current() {
  input_name="$1"
  channel_name="$(jq <npins/sources.json -r ".pins.$input_name.name")"

  latest="$(latest_nixpkgs "$channel_name")"
  mine="$(my_nixpkgs "$input_name")"

  echo "checking $channel_name:"
  echo "latest = $latest"
  echo "mine   = $mine"
  echo

  [ "$latest" = "$mine" ]
}

if is_current nixpkgs && is_current nixos; then
  echo "no updates: all done"
  exit 0
fi

echo "latest nixpkgs doesn't match my version. updating flake inputs..."
npins update
git config user.email "gitlab@matt.mattmoriarity.com"
git config user.name "GitLab Automation"
git add npins/sources.json
git commit -m "npins update"
git remote add gitlab "https://ci:$FLAKE_UPDATE_TOKEN@$CI_SERVER_HOST/$CI_PROJECT_PATH.git" || true
git push gitlab HEAD:main
