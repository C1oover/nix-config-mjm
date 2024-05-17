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

def --wrapped "darwin rebuild" [...args] {
  nom-build hosts/darwin.nix -A $'(scutil --get LocalHostName).system' ...$args
  nvd diff /run/current-system ./result
}

def "darwin switch" [] {
  sudo -H --preserve-env=PATH env nix-env -p /nix/var/nix/profiles/system --set (readlink -f result)
  $"(pwd)/result/activate-user"
  sudo -H --preserve-env=PATH ./result/activate
}

def --wrapped "linux rebuild" [...args] {
  colmena build --on (hostname) --keep-result -v ...$args
  nvd diff /run/current-system $'.gcroots/node-(hostname)'
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
