#!/usr/bin/env nu

use helpers.nu *

with-vault {
  let token = vault kv get -field=attic_token kv/prod/repos/nix-config
  attic login --set-default homelab https://attic.midna.dev $token
}
