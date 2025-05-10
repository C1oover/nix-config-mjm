package main

import (
	"context"
	"fmt"
	"log/slog"
	"slices"

	"git.midna.dev/mjm/nix-config/packages/dippy/infra"
)

type DeployFlags struct {
	Nom   bool   `help:"Use nix-output-monitor for nice build output." default:"${ci_false}" negatable:""`
	Attic bool   `help:"Push built systems to the attic cache." default:"true" negatable:""`
	Tests bool   `help:"Run NixOS VM tests." default:"${ci_true}" negatable:""`
	Goal  string `help:"Use a specific goal instead of choosing automatically." short:"g" enum:",switch,boot" default:""`
}

type DeployCmd struct {
	DeployFlags
	Hosts []string `arg:"" name:"host" help:"Hosts to deploy." optional:""`
}

func (c *DeployCmd) Run(ctx context.Context, cli *CLI) error {
	cfg, err := GenerateConfig(ctx)
	if err != nil {
		return fmt.Errorf("generating config: %w", err)
	}
	defer cfg.Cleanup()

	s := sectionStart("Evaluating hosts and tests", true)
	plan, err := cli.EvalNodes(ctx, &cfg, c.Hosts)
	if err != nil {
		return fmt.Errorf("evaluating nodes: %w", err)
	}
	sectionEnd(s)

	plan.ForceGoal = c.Goal
	// remove any local hosts, we don't want to deploy to those
	plan.Hosts = slices.DeleteFunc(plan.Hosts, func(h *Host) bool {
		return h.IsLocal()
	})

	s = sectionStart("Building hosts", false)
	if err := plan.Build(ctx, c.Nom); err != nil {
		return fmt.Errorf("building all hosts: %w", err)
	}
	sectionEnd(s)

	if c.Tests {
		s = sectionStart("Running NixOS VM tests", false)
		if err := plan.Test(ctx, c.Nom); err != nil {
			return fmt.Errorf("running all tests: %w", err)
		}
		sectionEnd(s)
	}

	if err := atticLogin(ctx, &cfg); err != nil {
		return fmt.Errorf("logging in to attic: %w", err)
	}

	s = sectionStart("Pushing systems to hosts and attic", true)
	if err := plan.EachHost(ctx, cli.Concurrency, func(ctx context.Context, h *Host) error {
		if err := h.Push(ctx); err != nil {
			return fmt.Errorf("pushing node %s: %w", h.Name, err)
		}
		if c.Attic {
			if err := h.PushToAttic(ctx); err != nil {
				return fmt.Errorf("pushing node %s to attic: %w", h.Name, err)
			}
		}
		if err := h.CheckRebootNeeded(ctx); err != nil {
			return fmt.Errorf("checking if reboot is needed on %s: %w", h.Name, err)
		}
		return nil
	}); err != nil {
		return fmt.Errorf("building nodes: %w", err)
	}
	sectionEnd(s)

	if len(c.Hosts) == 0 {
		vault, err := cfg.Vault(ctx)
		if err != nil {
			return fmt.Errorf("getting vault client: %w", err)
		}

		s = sectionStart("Applying infra changes", false)
		if err := infra.Apply(ctx, vault, plan.Infra); err != nil {
			return fmt.Errorf("applying infra changes: %w", err)
		}
		sectionEnd(s)
	}

	s = sectionStart("Deploying", false)
	if err := plan.Deploy(ctx); err != nil {
		return fmt.Errorf("deploying plan: %w", err)
	}

	slog.InfoContext(ctx, "deploy completed")
	sectionEnd(s)

	return nil
}
