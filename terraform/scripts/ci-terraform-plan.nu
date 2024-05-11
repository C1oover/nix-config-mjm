#!/usr/bin/env nu

use helpers.nu *

with-vault {
  with-tofu {
    tofu init
    tofu plan
  }
}
