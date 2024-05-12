#!/usr/bin/env nu

use helpers.nu *

colmena build --on @phase-main,@phase-ingress --keep-result

retry -n 5 {
  attic push homelab .gcroots/node-*
}
