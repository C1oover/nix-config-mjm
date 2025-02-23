package main

import (
	"context"
	"fmt"
	"log/slog"
	"slices"

	"git.midna.dev/mjm/nix-config/packages/nixos-deploy/nix"
	"golang.org/x/sync/errgroup"
)

// DeployPlan is a plan for how to do a phased rollout of deploys to a set of hosts.
type DeployPlan struct {
	Phases []DeployPhase
	Hosts  []*Host
	Tests  []nix.EvalJobResult
	cfg    Config
}

type planConfig struct {
	Phases     []DeployPhase           `json:"phases"`
	Deployment map[string]DeployConfig `json:"deployment"`
}

// DeployPhase is a single phase in a deploy. It is a group of nodes that should be
// deployed at a particular point during the deploy.
type DeployPhase struct {
	Name  string   `json:"name"`
	Nodes []string `json:"nodes"`
}

// ContainsHost returns true if any of the phases in the plan contain the host with
// the given name.
func (p *DeployPlan) ContainsHost(name string) bool {
	return slices.ContainsFunc(p.Phases, func(p DeployPhase) bool {
		return slices.Contains(p.Nodes, name)
	})
}

// EachHost runs a function concurrently for each host in the plan, regardless of
// the host's phase, if any. The maximum number of active functions running at one
// time is controlled by the -concurrency CLI flag. If any hosts return an error
// from the function, the first one will be returned.
func (p *DeployPlan) EachHost(ctx context.Context, f func(context.Context, *Host) error) error {
	g, childCtx := errgroup.WithContext(ctx)
	g.SetLimit(*concurrency)

	for _, h := range p.Hosts {
		g.Go(func() error {
			return f(childCtx, h)
		})
	}
	return g.Wait()
}

func (p *DeployPlan) Build(ctx context.Context, useNom bool) error {
	var drvPaths []string
	for _, h := range p.Hosts {
		drvPaths = append(drvPaths, h.DrvPath)
	}

	if err := p.cfg.Nix.Realise(ctx, drvPaths, useNom); err != nil {
		return fmt.Errorf("building plan hosts: %w", err)
	}

	return nil
}

func (p *DeployPlan) Test(ctx context.Context, useNom bool) error {
	var drvPaths []string
	for _, h := range p.Tests {
		drvPaths = append(drvPaths, h.DrvPath)
	}

	if err := p.cfg.Nix.Realise(ctx, drvPaths, useNom); err != nil {
		return fmt.Errorf("running plan tests: %w", err)
	}

	return nil
}

// Deploy will deploy each phase in the plan in sequence. Any hosts that are in
// the plan but not named in any phase will not be deployed.
func (p *DeployPlan) Deploy(ctx context.Context) error {
	nodesByName := map[string]*Host{}
	for _, h := range p.Hosts {
		nodesByName[h.Name] = h
	}

	for _, phase := range p.Phases {
		var phaseNodes []*Host
		for _, name := range phase.Nodes {
			if h, ok := nodesByName[name]; ok {
				phaseNodes = append(phaseNodes, h)
			}
		}

		if err := p.deployPhaseHosts(ctx, phase.Name, phaseNodes); err != nil {
			return fmt.Errorf("deploying phase %s: %w", phase.Name, err)
		}
	}

	return nil
}

func (_ DeployPlan) deployPhaseHosts(ctx context.Context, name string, hosts []*Host) error {
	if len(hosts) == 0 {
		return nil
	}

	l := slog.Default().WithGroup("phase").With("name", name)
	l.InfoContext(ctx, "deploying phase", "host_count", len(hosts))

	for _, h := range hosts {
		if err := h.Deploy(ctx); err != nil {
			return fmt.Errorf("deploying %s: %w", h.Name, err)
		}
	}

	l.InfoContext(ctx, "deployed phase")
	return nil
}
