#!/usr/bin/env nu

def main [action: string = switch] {
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
