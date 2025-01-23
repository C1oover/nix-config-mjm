use nu-lib *
use nu-lib/deploy.nu *
use nu-lib/vault.nu *

def --wrapped "darwin rebuild" [...args] {
  let out_path = nom-build hosts/darwin.nix -A $'(scutil --get LocalHostName).system' ...$args
  nvd diff /run/current-system $out_path

  loop {
    match (input "Apply these changes with switch goal? " | str downcase) {
      "y" | "yes" => { break }
      "n" | "no" => { return null }
    }
  }

  sudo -H --preserve-env=PATH env nix-env -p /nix/var/nix/profiles/system --set $out_path
  /nix/var/nix/profiles/system/activate-user
  sudo -H --preserve-env=PATH /nix/var/nix/profiles/system/activate
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

def "main deploy" [...hosts] {
  with-temp-key {|key|
    nixos-deploy --ssh-identity-file $key deploy ...$hosts
  }
}

def "main diff" [...hosts] {
  with-temp-key {|key|
    let text = nixos-deploy --ssh-identity-file $key diff ...$hosts
    if ($text | is-empty) {
      print "No changes."
    } else {
      print $text
    }
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
      let comment_text = nixos-deploy --ssh-identity-file $ssh_key diff
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
