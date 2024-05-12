#!/usr/bin/env nu

def --wrapped main [...args] {
  colmena build --on (hostname) --keep-result -v ...$args
  nvd diff /run/current-system $'.gcroots/node-(hostname)'
}
