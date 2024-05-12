#!/usr/bin/env nu

use helpers.nu *

with-vault {
  with-temp-key {|key_path|
    let $config_file = $key_path | path dirname | path join ssh_config
    $'IdentityFile ($key_path)
    ' | save $config_file

    with-env {SSH_CONFIG_FILE: $config_file} {
      colmena apply --on @phase-main --keep-result
      # deploy to ingress last, since it can disrupt the build
      colmena apply --on @phase-ingress --keep-result
    }

    retry -n 5 {
      attic push homelab .gcroots/node-*
    }
  }
}
