#!/usr/bin/env nu

def --wrapped main [...args] {
  nom-build hosts/darwin.nix -A $'(scutil --get LocalHostName).system' ...$args
  nvd diff /run/current-system ./result
}
