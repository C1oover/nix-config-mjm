package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"os"
	"os/exec"
	"path"
	"runtime"
	"strconv"
	"strings"
	"time"

	"git.midna.dev/mjm/nix-config/packages/dippy/infra"
	"git.midna.dev/mjm/nix-config/packages/dippy/nix"
	"github.com/alecthomas/kong"
	"github.com/lmittmann/tint"
)

type CLI struct {
	Plans       string     `short:"f" help:"File to evaluate for deploy plans." type:"path" default:"plans.nix"`
	Concurrency int        `short:"j" help:"Number of nodes to evaluate concurrently." default:"${num_cpu}"`
	LogLevel    slog.Level `help:"Minimum log level to output." enum:"DEBUG,INFO,WARN,ERROR" default:"INFO"`

	Deploy DeployCmd `cmd:"" help:"Deploy one or more hosts." group:"remote_hosts"`
	Diff   DiffCmd   `cmd:"" help:"Build and diff one or more hosts." group:"remote_hosts"`
	Reboot RebootCmd `cmd:"" help:"Reboot a host and wait for it to be healthy." group:"remote_hosts"`

	ApplyLocal ApplyLocalCmd `cmd:"" help:"Apply config for the local host." group:"local_hosts"`

	Infra struct {
		Apply ApplyInfraCmd `cmd:"" help:"Apply infrastructure changes with Pulumi."`
		Diff  DiffInfraCmd  `cmd:"" help:"Preview (but don't apply) infrastructure changes with Pulumi."`
	} `cmd:"" group:"infra"`
}

func main() {
	ctx := context.Background()

	var cli CLI

	// This is probably a dumb way to do this, and an actual resolver would be better
	ciTrue := "false"
	ciFalse := "true"
	if os.Getenv("CI") != "" {
		ciTrue = "true"
		ciFalse = "false"
	}
	c := kong.Parse(&cli, kong.BindTo(ctx, (*context.Context)(nil)), kong.Vars{
		"num_cpu":  strconv.Itoa(runtime.NumCPU()),
		"ci_true":  ciTrue,
		"ci_false": ciFalse,
	}, kong.ExplicitGroups([]kong.Group{
		{
			Key:   "remote_hosts",
			Title: "Work with remote hosts:",
		},
		{
			Key:   "local_hosts",
			Title: "Work with the local host:",
		},
		{
			Key:   "infra",
			Title: "Manage host-agnostic infrastructure:",
		},
	}))

	logger := slog.New(tint.NewHandler(os.Stderr, &tint.Options{
		Level:      slog.Level(cli.LogLevel),
		TimeFormat: time.Kitchen,
	}))
	slog.SetDefault(logger)

	if err := c.Run(ctx); err != nil {
		slog.ErrorContext(ctx, "command failed", "error", err)
		os.Exit(1)
	}
}

func (cli *CLI) EvalNodes(ctx context.Context, cfg *Config, hostnames []string) (*DeployPlan, error) {
	if hostnames == nil {
		hostnames = []string{}
	}
	slog.InfoContext(ctx, "evaluating plans", "file", cli.Plans, "hosts", hostnames, "workers", cli.Concurrency)

	hostnamesBytes, err := json.Marshal(hostnames)
	if err != nil {
		return nil, fmt.Errorf("serializing hostnames to json: %w", err)
	}

	namesToInclude := fmt.Sprintf("builtins.fromJSON %q", string(hostnamesBytes))
	paths, err := cfg.Nix.EvalJobs(ctx, nix.EvalJobsOptions{
		Path: cli.Plans,
		Args: map[string]string{
			"namesToInclude": namesToInclude,
		},
		Workers: cli.Concurrency,
	})
	if err != nil {
		return nil, fmt.Errorf("running eval: %w", err)
	}

	var configResult, infraResult nix.EvalJobResult
	var errorAttrs []string
	var testResults []nix.EvalJobResult
	resultsByAttrs := map[string]nix.EvalJobResult{}
	for _, r := range paths {
		if r.Error != "" {
			errorAttrs = append(errorAttrs, r.Attr)
		} else if r.Attr == "configJson" {
			configResult = r
		} else if r.Attr == "infraJson" {
			infraResult = r
		} else if r.AttrPath[0] == "toplevels" {
			resultsByAttrs[r.AttrPath[1]] = r
		} else if r.AttrPath[0] == "tests" {
			testResults = append(testResults, r)
		}
	}
	if len(errorAttrs) > 0 {
		return nil, fmt.Errorf("evaluation failed for one or more attributes (%s)", strings.Join(errorAttrs, ", "))
	}

	var plan planConfig
	if err := realiseJSON(ctx, cfg, configResult, &plan); err != nil {
		return nil, fmt.Errorf("realising config json: %w", err)
	}

	infraInput := new(infra.Input)
	if err := realiseJSON(ctx, cfg, infraResult, infraInput); err != nil {
		return nil, fmt.Errorf("realising infra json: %w", err)
	}

	slog.DebugContext(ctx, "infra input", "input", infraInput)

	dp := &DeployPlan{
		Phases: plan.Phases,
		Tests:  testResults,
		Infra:  infraInput,
		cfg:    cfg,
	}
	for name, r := range resultsByAttrs {
		if !dp.ContainsHost(name) {
			continue
		}

		h := NewHost(cfg, name, r.System, r.DrvPath, r.OutPath(), plan.Deployment[name])
		dp.Hosts = append(dp.Hosts, h)
	}
	return dp, nil
}

func realiseJSON(ctx context.Context, cfg *Config, result nix.EvalJobResult, v any) error {
	if err := cfg.Nix.Realise(ctx, []string{result.DrvPath}, false); err != nil {
		return fmt.Errorf("realising %q: %w", result.DrvPath, err)
	}

	f, err := os.Open(result.OutPath())
	if err != nil {
		return fmt.Errorf("opening %q: %w", result.OutPath(), err)
	}
	defer f.Close()

	if err := json.NewDecoder(f).Decode(v); err != nil {
		return fmt.Errorf("decoding json: %w", err)
	}

	return nil
}

func aggregateDiffs(ctx context.Context, dir string) (*AggregatedDiff, error) {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, fmt.Errorf("reading entries from diffs dir: %w", err)
	}

	var paths []string
	for _, e := range entries {
		paths = append(paths, path.Join(dir, e.Name()))
	}

	args := append([]string{"aggregate"}, paths...)
	cmd := exec.CommandContext(ctx, "nvd-json", args...)
	cmd.Stderr = os.Stderr

	out, err := cmd.StdoutPipe()
	if err != nil {
		return nil, fmt.Errorf("creating stdout pipe for nvd-json: %w", err)
	}
	defer out.Close()

	if err := cmd.Start(); err != nil {
		return nil, fmt.Errorf("starting nvd-json: %w", err)
	}

	var d AggregatedDiff
	if err := json.NewDecoder(out).Decode(&d); err != nil {
		return nil, fmt.Errorf("decoding diff from nvd-json: %w", err)
	}

	if err := cmd.Wait(); err != nil {
		return nil, fmt.Errorf("waiting for nvd-json to finish: %w", err)
	}

	return &d, nil
}
