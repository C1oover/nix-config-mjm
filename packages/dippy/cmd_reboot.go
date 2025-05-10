package main

import (
	"context"
	"fmt"
)

type RebootCmd struct {
	Host string `arg:"" help:"Host to reboot."`
}

func (c *RebootCmd) Run(ctx context.Context, cli *CLI) error {
	cfg, err := GenerateConfig(ctx)
	if err != nil {
		return fmt.Errorf("generating config: %w", err)
	}
	defer cfg.Cleanup()

	plan, err := cli.EvalNodes(ctx, &cfg, []string{c.Host})
	if err != nil {
		return fmt.Errorf("evaluating nodes: %w", err)
	}

	if err := plan.Hosts[0].Reboot(ctx); err != nil {
		return fmt.Errorf("rebooting node: %w", err)
	}

	if err := plan.Hosts[0].WaitUntilHealthy(ctx); err != nil {
		return fmt.Errorf("waiting for node to be healthy: %w", err)
	}

	return nil
}
