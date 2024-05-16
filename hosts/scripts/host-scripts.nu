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
    valid_principals=matt) o> $"($key_path)-cert.pub"

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

def --wrapped "main deploy" [...args] {
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

def "main ci deploy" [--reboot] {
  with-vault {
    with-temp-key {|key_path|
      let $config_file = $key_path | path dirname | path join ssh_config
      $'IdentityFile ($key_path)
      ' | save $config_file

      with-env {SSH_CONFIG_FILE: $config_file} {
        if $reboot {
          colmena apply --on @reboot-phase-main --keep-result --reboot
          # deploy to ingress last, since it can disrupt the build
          colmena apply --on @reboot-phase-ingress --keep-result --reboot
        } else {
          colmena apply --on @phase-main --keep-result
          # deploy to ingress last, since it can disrupt the build
          colmena apply --on @phase-ingress --keep-result
        }
      }

      retry -n 5 {
        attic push homelab .gcroots/node-*
      }
    }
  }
}

def "main ci build" [] {
  colmena build --on @phase-main,@phase-ingress --keep-result

  retry -n 5 {
    attic push homelab .gcroots/node-*
  }
}

def "main ci diff" [] {
  nvd diff /run/current-system .gcroots/node-hypnos
}

def "main ci attic-login" [] {
  with-vault {
    let token = vault kv get -field=attic_token kv/prod/repos/nix-config
    attic login --set-default homelab https://attic.midna.dev $token
  }
}

def main [] {}
