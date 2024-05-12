#!/usr/bin/env nu

use helpers.nu *

def --wrapped main [...args] {
  with-temp-key {|key_path|
    let config_file = $key_path | path dirname | path join ssh_config
    $'IdentityFile ($key_path)
    Host *
      UserKnownHostsFile ~/.ssh/known_hosts
    ' | save $config_file

    with-env {SSH_CONFIG_FILE: $config_file} {
      colmena apply ...$args
    }
  }
}
