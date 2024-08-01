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
    colmena exec -v --on $host -- system-upgrade-check -n $system_path
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
        colmena exec -v --on $host -- system-upgrade-check -n $system_path out+err> $'diffs/($host)'
        print $'($host): done'
      }
      cat diffs/*
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
