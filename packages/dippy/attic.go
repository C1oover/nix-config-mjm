package main

import (
	"context"
	"fmt"
)

func atticLogin(ctx context.Context, cfg *Config) error {
	token, err := cfg.GetSecret(ctx, "attic_token")
	if err != nil {
		return fmt.Errorf("reading attic token: %w", err)
	}

	// login with dippy's own server name to avoid overwriting an already set local token
	if err := cfg.Runner.Execute(ctx, "attic", "login", "homelab-dippy", "https://attic.midna.dev", token); err != nil {
		return fmt.Errorf("running attic login: %w", err)
	}

	return nil
}
