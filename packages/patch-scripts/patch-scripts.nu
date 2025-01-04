def update-patches [block] {
  let patches = open npins/patches.json
  do $block $patches | save -f npins/patches.json
}

def "main add" [
  name: string
  pr_id: string
] {
  let sources = open npins/sources.json
  update-patches {|patches|
    let source = $sources.pins | get $name
    let repo = $source.repository? | default {
      type: "GitHub"
      owner: "NixOS"
      repo: "nixpkgs"
    }
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

def main [] {}
