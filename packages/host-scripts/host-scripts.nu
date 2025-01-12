use nu-lib *
use nu-lib/deploy.nu *
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
  nixos-deploy apply-local
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
  }
}

def "main deploy" [...hosts] {
  with-temp-key {|key|
    nixos-deploy --ssh-identity-file $key deploy ...$hosts
  }
}

def "main diff" [...hosts] {
  with-temp-key {|key|
    nixos-deploy --ssh-identity-file $key diff ...$hosts
  }
}

def "main ci deploy" [] {
  with-vault {
    with-temp-key {|key|
      nixos-deploy --ssh-identity-file $key deploy
    }
  }
}

def "main ci diff" [] {
  with-vault {
    with-temp-key {|ssh_key|
      let results = nixos-deploy --ssh-identity-file $ssh_key diff | from json

      let keys = ['reboot_packages' 'version_changes' 'added_packages' 'removed_packages']
      let comment_text = $keys | where {|key| $results | get $key | is-not-empty } | each {|key|
        let heading = match $key {
          'reboot_packages' => 'Changes requiring reboot'
          'version_changes' => 'Version changes'
          'added_packages' => 'Added'
          'removed_packages' => 'Removed'
        }

        let changes_list = $results | get $key | each {|change|
          let hosts_list = $change.hosts | each {|host|
            let versions = ['old_versions' 'new_versions'] | each {|key|
              $host | get -i $key
            } | each {|list| $list | str join ", " } | str join " -> "

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

      if ($env.CI_API_V4_URL? | is-empty) {
        print -e "Would post the following comment to GitLab:\n"
        print $body
      } else {
        (gitlab mr note create
          --url $env.CI_API_V4_URL
          --token $env.PINS_UPDATE_TOKEN
          --project $env.CI_PROJECT_ID
          --mr $env.CI_MERGE_REQUEST_IID
          --body $body)

        print -e "posted comment to merge request"
      }
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
