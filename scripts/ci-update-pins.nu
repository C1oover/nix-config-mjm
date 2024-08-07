#!/usr/bin/env nu

export def latest-nixpkgs [name] {
  (http head -R m $"https://channels.nixos.org/($name)/nixexprs.tar.xz" |
    where name == location |
    get value.0)
}

export def get-pin [name] {
  open npins/sources.json | get pins | get $name
}

export def is-current [name] {
  let pin = get-pin $name
  let latest = latest-nixpkgs $pin.name
  let mine = $pin.url

  print $"checking ($pin.name):"
  print $"latest = ($latest)"
  print $"mine   = ($mine)"

  $latest == $mine
}

export def existing-mrs [
  --url: string
  --project: string
  --token: string
] {
  let filters = {
    source_branch: npins-update
    target_branch: main
    state: opened
  } | url build-query

  (http get
    --headers [Authorization $"Bearer ($token)"]
    $"($url)/projects/($project)/merge_requests?($filters)")
}

export def create-mr [
  --url: string
  --project: string
  --token: string
  --description: string = ""
] {
  let body = {
    title: "npins update"
    description: $description
    source_branch: "npins-update"
    target_branch: "main"
    assignee_id: 2
    remove_source_branch: true
  }

  (http post
    --content-type application/json
    --headers [Authorization $"Bearer ($token)"]
    $"($url)/projects/($project)/merge_requests"
    $body)
}

def main [] {
  let url = $env.CI_API_V4_URL
  let project = $env.CI_PROJECT_ID
  let token = $env.PINS_UPDATE_TOKEN

  let mr_count = existing-mrs --url $url --project $project --token $token | length
  if $mr_count > 0 {
    print "existing update merge request already open. doing nothing."
    return
  }

  if (is-current nixpkgs) and (is-current nixos) {
    print "no updates: all done"
    return
  }

  print "latest nixpkgs doesn't match my version. updating pinned sources..."
  let output = npins update o+e>| $in
  git config user.email "gitlab@mj.midna.dev"
  git config user.name "Pins Updater"
  git add npins/sources.json
  git commit -m "npins update"
  try {
    git remote add gitlab $"https://ci:($token)@($env.CI_SERVER_HOST)/($env.CI_PROJECT_PATH).git"
  }
  git push -f gitlab HEAD:refs/heads/npins-update

  print "creating merge request..."
  create-mr --url $url --project $project --token $token --description $"```\n($output)\n```"
}
