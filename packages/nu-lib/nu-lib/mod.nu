export module nu-lib/gitlab.nu

export def retry [block, -n: int] {
  try {
    do -c $block
  } catch {|e|
    if $n == 1 {
      error make $e.raw
    } else {
      retry -n ($n - 1) $block
    }
  }
}
