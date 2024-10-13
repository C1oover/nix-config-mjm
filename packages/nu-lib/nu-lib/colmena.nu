def with-temp-key [block] {
  let key_dir = mktemp -d
  let key_path = $key_dir | path join id_ed25519

  ssh-keygen -t ed25519 -f $key_path -N ""

  (vault write
    -field=signed_key
    ssh-client-signer/sign/homelab-client
    $"public_key=@($key_path).pub"
    valid_principals=matt) | save $"($key_path)-cert.pub"

  try {
    do -c $block $key_path
    remove-temp-key $key_dir
  } catch {|e|
    remove-temp-key $key_dir
    error make $e.raw
  }
}

def remove-temp-key [dir] {
  print -e $"Removing temp directory ($dir)"
  rm -rf $dir
}

export def with-colmena [block, --use-known-hosts] {
  with-temp-key {|key_path|
    let config_file = $key_path | path dirname | path join ssh_config
    ($'IdentityFile ($key_path)' | if $use_known_hosts {
      $in ++ '
      Host *
        UserKnownHostsFile ~/.ssh/known_hosts'
    } else { $in } | save $config_file)

    with-env {SSH_CONFIG_FILE: $config_file} {
      do -c $block
    }
  }
}

export def --wrapped "colmena-exec-raw" [host ...args] {
  with-env {NO_COLOR: 1} {
    (colmena exec
      -v --color never
      --on $host
      --
      ...$args
      err>| lines | where {|line|
        (not ($line | str starts-with '[') and
          not ($line | str ends-with 'Succeeded') and
          not ($line | str ends-with 'All done!'))
      }) | each {|line|
        $line | str replace $'($host) | ' ''
      } | str join "\n"
  }
}

export def nodes-by-phase [] {
  colmena eval -E '{nodes,lib,...}: lib.genAttrs ["normal" "reboot"] (k: let phaseKey = { normal = "phase"; reboot = "rebootPhase"; }.${k}; in builtins.groupBy (n: let phase = nodes.${n}.config.deployment.${phaseKey}; in if phase == null then "" else phase) (lib.attrNames nodes))' | from json
}

export def apply-nodes [
  --nodes: list
  --reboot
  reboot_needs: record
] {
  let actual_nodes = $nodes | where {|n| $reboot == ($reboot_needs | get $n) }
  if ($actual_nodes | is-not-empty) {
    let on_str = $actual_nodes | str join ","
    if $reboot {
      print $'Deploying to ($actual_nodes | str join ", ") by rebooting...'
      colmena apply --on $on_str --reboot
    } else {
      print $'Deploying to ($actual_nodes | str join ", ")...'
      colmena apply --on $on_str
    }
  }
}
