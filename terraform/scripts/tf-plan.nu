#!/usr/bin/env nu

use helpers.nu *

def --wrapped main [...args] {
  with-tofu {
    tofu init
    tofu plan ...$args
  }
}
