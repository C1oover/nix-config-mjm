use nu-lib gitlab

def latest-nixpkgs [name] {
  (http head -R m $"https://channels.nixos.org/($name)/nixexprs.tar.xz" |
    where name == location |
    get value.0)
}

def latest-git [url branch] {
  (git ls-remote $url $branch |
    split row "\t" |
    get 0)
}

def get-pin [name] {
  open npins/sources.json | get pins | get $name
}

def is-current [name] {
  let pin = get-pin $name

  let name = match $pin.type {
    "Channel" => $pin.name,
    "Git" => {
      $pin.branch | str replace 'deploy/' ''
    }
  }
  print $"checking ($name):"

  let latest = match $pin.type {
    "Channel" => {
      latest-nixpkgs $pin.name
    },
    "Git" => {
      let url = $"($pin.repository.server)($pin.repository.repo_path).git"
      latest-git $url $pin.branch
    }
  }
  let mine = match $pin.type {
    "Channel" => $pin.url,
    "Git" => $pin.revision,
  }

  print $"latest = ($latest)"
  print $"mine   = ($mine)"

  $latest == $mine
}

def existing-mrs [
  --url: string
  --project: string
  --token: string
] {
  let filters = {
    source_branch: npins-update
    target_branch: main
    state: opened
  }

  gitlab mr list --url $url --project $project --token $token --filters $filters
}

export def create-mr [
  --url: string
  --project: string
  --token: string
  --channels: list
  --description: string = ""
  --auto-merge
] {
  let body = {
    title: $"npins update: ($channels | str join ', ')"
    description: $description
    source_branch: "npins-update"
    target_branch: "main"
    assignee_id: 2
    remove_source_branch: true
  }

  let result = (gitlab mr create
    --url $url
    --project $project
    --token $token
    $body)

  if $auto_merge {
    # Auto-merging requires that the pipeline exists and that the MR
    # is "mergable", which is checked asynchronously. I could poll
    # to check those things, and maybe I will if this still has
    # issues, but there's no rush so we'll just wait a reasonably
    # long time before trying.
    sleep 20sec

    let body = {merge_when_pipeline_succeeds: true}
    (http put
      --content-type application/json
      --headers [Authorization $"Bearer ($token)"]
      $"($url)/projects/($project)/merge_requests/($result.iid)/merge"
      $body)
  }
}

def "main ci update-pins" [] {
  let url = $env.CI_API_V4_URL
  let project = $env.CI_PROJECT_ID
  let token = $env.PINS_UPDATE_TOKEN

  let mr_count = existing-mrs --url $url --project $project --token $token | length
  if $mr_count > 0 {
    print "existing update merge request already open. doing nothing."
    return
  }

  let outdated_channels = ["nixpkgs" "nixos" "nixos-small"] | where {|ch| not (is-current $ch) }
  if ($outdated_channels | is-empty) {
    print "no updates: all done"
    return
  }

  let auto_merge = "nixos-small" not-in $outdated_channels

  print "latest nixpkgs doesn't match my version. updating pinned sources..."
  let output = npins update | tee { print }
  git config user.email "gitlab@mj.midna.dev"
  git config user.name "Pins Updater"
  git add npins/sources.json
  git commit -m "npins update"
  try {
    git remote add gitlab $"https://ci:($token)@($env.CI_SERVER_HOST)/($env.CI_PROJECT_PATH).git"
  }
  git push -f gitlab HEAD:refs/heads/npins-update

  print "creating merge request..."
  (create-mr
    --url $url
    --project $project
    --token $token
    --channels $outdated_channels
    --auto-merge=$auto_merge
    --description $"```\n($output)\n```")
}

def main [] {}
