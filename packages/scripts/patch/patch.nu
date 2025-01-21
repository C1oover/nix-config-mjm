def update-patches [block] {
  let patches = open npins/patches.json
  do $block $patches | save -f npins/patches.json
}

def get-repo [sources name] {
  let source = $sources.pins | get $name
  $source.repository? | default {
    type: "GitHub"
    owner: "NixOS"
    repo: "nixpkgs"
  }
}

def "main add" [
  name: string
  pr_id: string
] {
  let sources = open npins/sources.json
  update-patches {|patches|
    let repo = get-repo $sources $name
    let url = $"https://github.com/($repo.owner)/($repo.repo)/pull/($pr_id).diff?full_index=1"
    let hash = nurl --fetcher fetchpatch2 --hash $url

    let cell_path = [$name $pr_id "hash"] | into cell-path
    $patches | upsert $cell_path $hash
  }
}

def "main remove" [
  name: string
  pr_id: string
] {
  update-patches {|patches|
    let cell_path = [$name $pr_id] | into cell-path
    $patches | reject $cell_path
  }
}

def "main list" [] {
  let sources = open npins/sources.json
  let patches = open npins/patches.json

  let names = $patches | columns | filter {|e| $patches | get $e | is-not-empty }

  $names | each {|name|
    let repo = get-repo $sources $name
    print $'($name):'
    $patches | get $name | columns | each {|pr_id|
      let title = http get $'https://api.github.com/repos/($repo.owner)/($repo.repo)/pulls/($pr_id)' | get title
      print $'  #($pr_id): ($title)'
    }
  } | ignore
}

def main [] {}
