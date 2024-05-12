#!/usr/bin/env nu

sudo -H --preserve-env=PATH env nix-env -p /nix/var/nix/profiles/system --set (readlink -f result)
$"(pwd)/result/activate-user"
sudo -H --preserve-env=PATH ./result/activate
