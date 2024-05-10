existing_pr_count="$(curl "$CI_API_V4_URL/projects/$CI_PROJECT_ID/merge_requests?source_branch=npins-update&target_branch=main&state=opened" -H "Authorization: Bearer $PINS_UPDATE_TOKEN" | jq length)"

if [ "x$existing_pr_count" != x0 ]; then
  echo "existing update merge request already open. doing nothing."
  exit 0
fi

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

echo "latest nixpkgs doesn't match my version. updating pinned sources..."
npins update
git config user.email "gitlab@matt.mattmoriarity.com"
git config user.name "GitLab Automation"
git add npins/sources.json
git commit -m "npins update"
git remote add gitlab "https://ci:$PINS_UPDATE_TOKEN@$CI_SERVER_HOST/$CI_PROJECT_PATH.git" || true
git push -f gitlab HEAD:npins-update

echo "creating merge request..."
curl "$CI_API_V4_URL/projects/$CI_PROJECT_ID/merge_requests" \
  -X POST \
  -H "Authorization: Bearer $PINS_UPDATE_TOKEN" \
  -d "{\"source_branch\":\"npins-update\",\"target_branch\":\"main\",\"title\":\"npins update\",\"assignee_id\":2}"
