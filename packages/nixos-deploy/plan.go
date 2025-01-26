package main

import (
	"context"
	"fmt"
	"log/slog"
	"slices"

	"golang.org/x/sync/errgroup"
)

type DeployPlan struct {
	Phases []DeployPhase
	Hosts  []*Host
}

type planConfig struct {
	Phases     []DeployPhase           `json:"phases"`
	Deployment map[string]DeployConfig `json:"deployment"`
}

type DeployPhase struct {
	Name  string   `json:"name"`
	Nodes []string `json:"nodes"`
}

func (p *DeployPlan) ContainsHost(name string) bool {
	return slices.ContainsFunc(p.Phases, func(p DeployPhase) bool {
		return slices.Contains(p.Nodes, name)
	})
}

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
