#!/usr/bin/env nu

use helpers.nu *

def main [...args] {
  link-tf-config
  tofu init
  tofu plan ...$args
}
