use nu-lib *
use nu-lib/colmena.nu *
use nu-lib/vault.nu *

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
  nvd diff /run/current-system $system_path
  let result = ^($system_path | path join bin/nvd-json) reboot-check $system_path | from json
  if $result.reboot_needed {
    print 'Reboot needed.'
  }
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

def "main ci deploy" [--reboot] {
  with-vault {
    with-colmena {
      colmena apply --on @phase-main,@phase-ingress --keep-result push

      let phases = nodes-by-phase
      let node_names = $phases.normal | items {|k, v| if $k != "" { $v } } | compact | flatten
      let nodes = $node_names | par-each {|host|
        let system_path = readlink -f $'.gcroots/node-($host)'
        print $'($host): checking if reboot is needed for ($system_path)'
        let reboot_needed = (colmena-exec-raw $host
          $'($system_path)/bin/nvd-json'
          reboot-check
          $system_path | from json | get reboot_needed)
        print $'($host): done'

        {name: $host, reboot_needed: $reboot_needed}
      } | transpose -d -i -r

      apply-nodes --nodes $phases.normal.main $nodes

      # attempt to keep vault healthy while rebooting by only doing one at a time.
      # this will hopefully allow them to render their secrets successfully and not
      # have sshd start without its host certificate.
      $phases.reboot.vault | each {|node|
        apply-nodes --nodes [$node] --reboot $nodes
      }
      apply-nodes --nodes $phases.reboot.main --reboot $nodes

      apply-nodes --nodes $phases.normal.ingress $nodes
      apply-nodes --nodes $phases.reboot.ingress --reboot $nodes

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
      colmena apply --on @phase-main,@phase-ingress --keep-result push
      colmena build --on persephone,uranus --keep-result

      retry -n 5 {
        attic push homelab .gcroots/node-*
      }

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

      (gitlab mr note create
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
