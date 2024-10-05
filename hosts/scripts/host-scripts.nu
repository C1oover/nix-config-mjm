#!/usr/bin/env nu

export def with-vault [block] {
  let token = vault write -field=token auth/gitlab/login role=homelab-infra $"jwt=($env.VAULT_ID_TOKEN)"
  with-env {VAULT_TOKEN: $token} $block
}

export def with-temp-key [block] {
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

def with-colmena [block, --use-known-hosts] {
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

def post-mr-comment [
  --url: string
  --project: string
  --token: string
  --mr: string
  --body: string
] {
  let body = { body: $body };
  (http post
    --content-type application/json
    --headers [Authorization $"Bearer ($token)"]
    $"($url)/projects/($project)/merge_requests/($mr)/notes"
    $body)
}

def --wrapped "colmena-exec-raw" [host ...args] {
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

def --wrapped "darwin rebuild" [...args] {
  nom-build hosts/darwin.nix -A $'(scutil --get LocalHostName).system' ...$args
  nvd diff /run/current-system ./result
}

def "darwin switch" [] {
  sudo -H --preserve-env=PATH env nix-env -p /nix/var/nix/profiles/system --set (readlink -f result)
  ./result/activate-user
  sudo -H --preserve-env=PATH ./result/activate
}

def --wrapped "linux rebuild" [...args] {
  colmena build --on (hostname) --keep-result -v ...$args

  let system_path = $'.gcroots/node-(hostname)' | path expand
  system-upgrade-check $system_path
}

def "linux switch" [action: string = switch] {
  let built_system = $".gcroots/node-(hostname)"

  sudo nix-env -p /nix/var/nix/profiles/system --set (readlink -f $built_system)
  (sudo systemd-run
    -E LOCALE_ARCHIVE
    --collect
    --no-ask-password
    --pty
    --quiet
    --same-dir
    --service-type=exec
    --unit=nixos-rebuild-switch-to-configuration
    --wait
    $'($built_system)/bin/switch-to-configuration'
    $action)
}

def --wrapped "main rebuild" [...args] {
  if (uname).operating-system == "Darwin" {
    darwin rebuild ...$args
  } else {
    linux rebuild ...$args
  }
}

def "main switch" [action: string = switch] {
  if (uname).operating-system == "Darwin" {
    darwin switch
  } else {
    linux switch $action
  }
}

def "main diff" [host: string] {
  with-colmena --use-known-hosts {
    colmena apply --on $host --keep-result push
    let system_path = readlink -f $'.gcroots/node-($host)'
    (colmena-exec-raw $host
      $'($system_path)/bin/nvd-json'
      diff
      /run/current-system
      $system_path | save -f $'/tmp/($host).json')
    let results = nvd-json aggregate $'/tmp/($host).json' | from json

    if ($results.version_changes | is-not-empty) {
      print "Version changes:"

      $results.version_changes | each {|it|
        print $'- ($it.pname):'

        $it.hosts | each {|it|
          print -n $'    ($it.hostname): '
          if ($it.old_versions? | is-not-empty) {
            $it.old_versions | str join ", " | print -n
            if ($it.new_versions? | is-not-empty) {
              print -n " -> "
            }
          }
          if ($it.new_versions? | is-not-empty) {
            $it.new_versions | str join ", " | print -n
          }
          print ''
        }
      }
    }

    if ($results.added_packages | is-not-empty) {
      print "Added:"

      $results.added_packages | each {|it|
        print $'- ($it.pname):'

        $it.hosts | each {|it|
          print -n $'    ($it.hostname): '
          $it.new_versions | str join ", " | print
          print ''
        }
      }
    }

    if ($results.removed_packages | is-not-empty) {
      print "Removed:"

      $results.removed_packages | each {|it|
        print $'- ($it.pname):'

        $it.hosts | each {|it|
          print -n $'    ($it.hostname): '
          $it.old_versions | str join ", " | print
          print ''
        }
      }
    }

    if ($results.reboot_packages | is-not-empty) {
      print "Reboot needed:"

      $results.reboot_packages | each {|it|
        print $'- ($it.pname):'

        $it.hosts | each {|it|
          print -n $'    ($it.hostname): '
          if ($it.old_versions? | is-not-empty) {
            $it.old_versions | str join ", " | print -n
            if ($it.new_versions? | is-not-empty) {
              print -n " -> "
            }
          }
          if ($it.new_versions? | is-not-empty) {
            $it.new_versions | str join ", " | print -n
          }
          print ''
        }
      }
    }

    print ''
  }
}

def --wrapped "main deploy" [...args] {
  with-colmena --use-known-hosts {
    colmena apply ...$args
  }
}

def nodes-by-phase [--option: string] {
  colmena eval -E $"{nodes,...}: builtins.groupBy \(n: let phase = nodes.${n}.config.deployment.($option); in if phase == null then \"\" else phase\) \(builtins.attrNames nodes\)" | from json
}

def apply-nodes [
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

def "main ci deploy" [--reboot] {
  with-vault {
    with-colmena {
      colmena apply --on @phase-main,@phase-ingress --keep-result push

      let normal_phases = nodes-by-phase --option phase
      let reboot_phases = nodes-by-phase --option rebootPhase

      let nodes = colmena eval -E '{ nodes, ... }: builtins.filter (n: nodes.${n}.config.deployment.phase != null) (builtins.attrNames nodes)' | from json | par-each {|host|
        let system_path = readlink -f $'.gcroots/node-($host)'
        print $'($host): checking if reboot is needed for ($system_path)'
        let reboot_needed = (colmena-exec-raw $host
          $'($system_path)/bin/nvd-json'
          reboot-check
          $system_path | from json | get reboot_needed)
        print $'($host): done'

        {name: $host, reboot_needed: $reboot_needed}
      } | transpose -d -i -r

      apply-nodes --nodes $normal_phases.main $nodes

      apply-nodes --nodes $reboot_phases.vault --reboot $nodes
      apply-nodes --nodes $reboot_phases.main --reboot $nodes

      apply-nodes --nodes $normal_phases.ingress $nodes
      apply-nodes --nodes $reboot_phases.ingress --reboot $nodes

      retry -n 60 {
        sleep 5sec
        attic push homelab .gcroots/node-*
      }
    }
  }
}

def "main ci build" [] {
  colmena build --keep-result

  retry -n 5 {
    attic push homelab .gcroots/node-*
  }
}

def "main ci diff" [] {
  with-vault {
    with-colmena {
      colmena build --keep-result

      retry -n 5 {
        attic push homelab .gcroots/node-*
      }

      colmena apply --on @phase-main,@phase-ingress --keep-result push

      mkdir diffs
      colmena eval -E '{ nodes, ... }: builtins.filter (n: nodes.${n}.config.deployment.phase != null) (builtins.attrNames nodes)' | from json | par-each {|host|
        let system_path = readlink -f $'.gcroots/node-($host)'
        print $'($host): diffing ($system_path) against current system'
        (colmena-exec-raw $host
          $'($system_path)/bin/nvd-json'
          diff
          /run/current-system
          $system_path | save -f $'diffs/($host).json')
        print $'($host): done'
      }

      let results = nvd-json aggregate diffs/*.json | from json;

      let keys = ['reboot_packages' 'version_changes' 'added_packages' 'removed_packages']
      let comment_text = $keys | where {|key| $results | get $key | is-not-empty } | each {|key|
        let heading = match $key {
          "reboot_packages" => "Changes requiring reboot"
          "version_changes" => "Version changes"
          "added_packages" => "Added"
          "removed_packages" => "Removed"
        }
        let changes = $results | get $key

        let changes_list = $results | get $key | each {|change|
          let hosts_list = $change.hosts | each {|host|
            let versions = ['old_versions' 'new_versions'] | each {|key| $host | get -i $key } |  each {|list| $list | str join ", " } | str join " -> "
            $'  - `($host.hostname)`: ($versions)'
          } | str join "\n"

          $'- **($change.pname)**
($hosts_list)'
        } | str join "\n"

        $'## ($heading)

($changes_list)'
      } | str join "\n\n"

      let body = if ($comment_text | is-empty) {
        "No package changes for server hosts."
      } else {
        $comment_text
      }

      (post-mr-comment
        --url $env.CI_API_V4_URL
        --token $env.PINS_UPDATE_TOKEN
        --project $env.CI_PROJECT_ID
        --mr $env.CI_MERGE_REQUEST_IID
        --body $body)

      print "posted comment to merge request"
    }
  }
}

def "main ci attic-login" [] {
  with-vault {
    let token = vault kv get -field=attic_token kv/prod/repos/nix-config
    attic login --set-default homelab https://attic.midna.dev $token
  }
}

def main [] {}
