#!/usr/bin/env nu

use helpers.nu *

with-vault {
  link-tf-config
  tofu init
  tofu plan
}
