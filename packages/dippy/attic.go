package main

import (
	"context"
	"fmt"
)

func atticLogin(ctx context.Context, cfg Config) error {
	secret, err := cfg.Vault.KVv2("kv").Get(ctx, "prod/repos/nix-config")
	if err != nil {
		return fmt.Errorf("reading nix-config vault secret: %w", err)
	}

	token := secret.Data["attic_token"].(string)

	// login with dippy's own server name to avoid overwriting an already set local token
	if err := cfg.Runner.Execute(ctx, "attic", "login", "homelab-dippy", "https://attic.midna.dev", token); err != nil {
		return fmt.Errorf("running attic login: %w", err)
	}

	return nil
}
