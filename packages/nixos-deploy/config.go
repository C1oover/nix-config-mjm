package main

import "git.midna.dev/mjm/nix-config/packages/nixos-deploy/cmd"

type Config struct {
	Runner  cmd.Runner
	SSHOpts []string
}
