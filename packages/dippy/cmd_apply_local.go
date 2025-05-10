package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"

	"git.midna.dev/mjm/nix-config/packages/dippy/nix"
)

type ApplyLocalCmd struct {
	Attic bool `help:"Push built systems to the attic cache." default:"true" negatable:""`
}

func (c *ApplyLocalCmd) Run(ctx context.Context, cli *CLI) error {
	cfg, err := NewLocalConfig()
	if err != nil {
		return fmt.Errorf("generating config: %w", err)
	}

	h, err := evalLocalNode(ctx, &cfg, cli.Plans)
	if err != nil {
		return fmt.Errorf("evaluating node: %w", err)
	}

	if err := h.Build(ctx, true); err != nil {
		return fmt.Errorf("building node: %w", err)
	}

	if c.Attic {
		if err := atticLogin(ctx, &cfg); err != nil {
			slog.WarnContext(ctx, "could not log in to attic. skipping push", "error", err)
		} else {
			if err := h.PushToAttic(ctx); err != nil {
				return fmt.Errorf("pushing to attic: %w", err)
			}
		}
	}

	if err := h.DiffLocal(ctx); err != nil {
		return fmt.Errorf("diffing node: %v", err)
	}

	if err := h.ApplyLocal(ctx); err != nil {
		return fmt.Errorf("applying to local node: %v", err)
	}

	return nil
}

func evalLocalNode(ctx context.Context, cfg *Config, path string) (*Host, error) {
	name, err := os.Hostname()
	if err != nil {
		return nil, fmt.Errorf("getting hostname: %w", err)
	}

	evalExpr := fmt.Sprintf("let config = (import <plans> {}).toplevels.%s; in { drv = config.drvPath; out = config.outPath; inherit (config) system; }", name)

	var result struct {
		DrvPath string `json:"drv"`
		OutPath string `json:"out"`
		System  string `json:"system"`
	}

	slog.InfoContext(ctx, "evaluating local host", "name", name)
	if err := cfg.Nix.EvalJSON(ctx, &result, nix.EvalOptions{
		Expr:    evalExpr,
		Include: []string{"plans=" + path},
	}); err != nil {
		return nil, fmt.Errorf("evaluating node: %w", err)
	}
	return NewHost(cfg, name, result.System, result.DrvPath, result.OutPath, DeployConfig{}), nil
}
