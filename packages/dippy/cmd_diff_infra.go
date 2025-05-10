package main

import (
	"context"
	"fmt"
	"log/slog"

	"git.midna.dev/mjm/nix-config/packages/dippy/infra"
	"git.midna.dev/mjm/nix-config/packages/dippy/nix"
)

type DiffInfraCmd struct{}

func (DiffInfraCmd) Run(ctx context.Context, cli *CLI) error {
	cfg, err := NewLocalConfig()
	if err != nil {
		return fmt.Errorf("generating config: %w", err)
	}

	slog.InfoContext(ctx, "evaluating infra config", "file", cli.Plans)

	result := new(infra.Input)
	if err := cfg.Nix.EvalJSON(ctx, result, nix.EvalOptions{
		Expr:    "(import <plans> {}).infra",
		Include: []string{"plans=" + cli.Plans},
	}); err != nil {
		return fmt.Errorf("evaluating infra data from nix: %w", err)
	}

	vault, err := cfg.Vault(ctx)
	if err != nil {
		return fmt.Errorf("getting vault client: %w", err)
	}

	if err := infra.Preview(ctx, vault, result); err != nil {
		return fmt.Errorf("previewing infra: %w", err)
	}

	return nil
}
