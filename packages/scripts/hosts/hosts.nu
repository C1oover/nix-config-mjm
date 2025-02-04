use nu-lib *
use nu-lib/vault.nu *

def "main deploy" [...hosts] {
  with-vault {
    nixos-deploy deploy ...$hosts
  }
}

def "main diff" [...hosts] {
  with-vault {
    let text = nixos-deploy diff ...$hosts
    if ($text | is-empty) {
      print "No changes."
    } else {
      print $text
    }
  }
}

def "main ci deploy" [] {
  with-vault {
    nixos-deploy deploy
  }
}

def "main ci diff" [] {
  with-vault {
    let comment_text = nixos-deploy diff
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

def "main ci attic-login" [] {
  with-vault {
    let token = vault kv get -field=attic_token kv/prod/repos/nix-config
    attic login --set-default homelab https://attic.midna.dev $token
  }
}

def main [] {}
