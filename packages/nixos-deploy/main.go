package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log/slog"
	"os"
	"os/exec"
	"path"
	"runtime"
	"slices"
	"strings"
	"time"

	"git.midna.dev/mjm/nix-config/packages/nixos-deploy/nix"
	"github.com/lmittmann/tint"
)

var (
	plansFile   = flag.String("plans", "plans.nix", "File to evaluate for deploy plans")
	concurrency = flag.Int("concurrency", runtime.NumCPU(), "Number of nodes to evaluate/build concurrently")

	logLevel slog.Level
)

func main() {
	flag.TextVar(&logLevel, "log-level", slog.LevelInfo, "Minimum log level to output")
	flag.Parse()
	ctx := context.Background()

	logger := slog.New(tint.NewHandler(os.Stderr, &tint.Options{
		Level:      logLevel,
		TimeFormat: time.Kitchen,
	}))
	slog.SetDefault(logger)

	var err error
	cmd := flag.Arg(0)
	switch cmd {
	case "deploy":
		err = handleDeploy(ctx)
	case "diff":
		err = handleDiff(ctx)
	case "reboot":
		err = handleReboot(ctx)
	case "apply-local":
		err = handleApplyLocal(ctx)
	default:
		slog.ErrorContext(ctx, "unexpected command", "command", cmd)
		os.Exit(1)
	}

	if err != nil {
		slog.ErrorContext(ctx, "command failed", "command", cmd, "error", err)
		os.Exit(1)
	}
}

func handleDeploy(ctx context.Context) error {
	hostnames := flag.Args()
	hostnames = hostnames[1:]

	cfg, err := GenerateConfig(ctx)
	if err != nil {
		return fmt.Errorf("generating config: %w", err)
	}
	defer cfg.Cleanup()

	plan, err := evalNodes(ctx, cfg, *plansFile, hostnames)
	if err != nil {
		return fmt.Errorf("evaluating nodes: %w", err)
	}

	// remove any local hosts, we don't want to deploy to those
	plan.Hosts = slices.DeleteFunc(plan.Hosts, func(h *Host) bool {
		return h.IsLocal()
	})

	if err := plan.Build(ctx); err != nil {
		return fmt.Errorf("building all hosts: %w", err)
	}

	if err := plan.EachHost(ctx, func(ctx context.Context, h *Host) error {
		if err := h.Test(ctx, false); err != nil {
			return fmt.Errorf("testing node %s: %w", h.Name, err)
		}
		if err := h.Push(ctx); err != nil {
			return fmt.Errorf("pushing node %s: %w", h.Name, err)
		}
		if err := h.PushToAttic(ctx); err != nil {
			return fmt.Errorf("pushing node %s to attic: %w", h.Name, err)
		}
		if err := h.CheckRebootNeeded(ctx); err != nil {
			return fmt.Errorf("checking if reboot is needed on %s: %w", h.Name, err)
		}
		return nil
	}); err != nil {
		return fmt.Errorf("building nodes: %w", err)
	}

	if err := plan.Deploy(ctx); err != nil {
		return fmt.Errorf("deploying plan: %w", err)
	}

	slog.InfoContext(ctx, "deploy completed")
	return nil
}

func handleDiff(ctx context.Context) error {
	hostnames := flag.Args()
	hostnames = hostnames[1:]

	cfg, err := GenerateConfig(ctx)
	if err != nil {
		return fmt.Errorf("generating config: %w", err)
	}
	defer cfg.Cleanup()

	plan, err := evalNodes(ctx, cfg, *plansFile, hostnames)
	if err != nil {
		return fmt.Errorf("evaluating nodes: %w", err)
	}

	slog.DebugContext(ctx, "creating temp dir for diffs")
	diffsDir, err := os.MkdirTemp("", "nixos-deploy-diffs")
	if err != nil {
		return fmt.Errorf("creating temp dir: %w", err)
	}
	defer os.RemoveAll(diffsDir)
	slog.DebugContext(ctx, "created temp dir for diffs", "path", diffsDir)

	if err := plan.Build(ctx); err != nil {
		return fmt.Errorf("building all hosts: %w", err)
	}

	if err := plan.EachHost(ctx, func(ctx context.Context, h *Host) error {
		if err := h.Test(ctx, false); err != nil {
			return fmt.Errorf("testing node %s: %w", h.Name, err)
		}
		if err := h.PushToAttic(ctx); err != nil {
			return fmt.Errorf("pushing node %s to attic: %w", h.Name, err)
		}

		if h.IsRemote() {
			if err := h.Push(ctx); err != nil {
				return fmt.Errorf("pushing node %s: %w", h.Name, err)
			}
			diff, err := h.Diff(ctx)
			if err != nil {
				return fmt.Errorf("diffing node %s: %w", h.Name, err)
			}

			f, err := os.Create(path.Join(diffsDir, fmt.Sprintf("%s.json", h.Name)))
			if err != nil {
				return fmt.Errorf("opening file to write diff: %w", err)
			}
			defer f.Close()

			if _, err := f.Write(diff); err != nil {
				return fmt.Errorf("writing diff to %s: %w", f.Name(), err)
			}
		}
		return nil
	}); err != nil {
		return fmt.Errorf("building nodes: %w", err)
	}

	slog.DebugContext(ctx, "aggregating diffs", "path", diffsDir)
	aggregated, err := aggregateDiffs(ctx, diffsDir)
	if err != nil {
		return fmt.Errorf("aggregating diffs: %w", err)
	}

	return aggregated.Write(os.Stdout)
}

func handleReboot(ctx context.Context) error {
	hostnames := flag.Args()
	hostnames = hostnames[1:]

	if len(hostnames) != 1 {
		return fmt.Errorf("reboot command requires exactly one host")
	}

	cfg, err := GenerateConfig(ctx)
	if err != nil {
		return fmt.Errorf("generating config: %w", err)
	}
	defer cfg.Cleanup()

	plan, err := evalNodes(ctx, cfg, *plansFile, hostnames)
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

func handleApplyLocal(ctx context.Context) error {
	h, err := evalLocalNode(ctx, *plansFile)
	if err != nil {
		return fmt.Errorf("evaluating node: %w", err)
	}

	if err := h.Build(ctx, true); err != nil {
		return fmt.Errorf("building node: %w", err)
	}

	if err := h.PushToAttic(ctx); err != nil {
		return fmt.Errorf("pushing to attic: %w", err)
	}

	if err := h.DiffLocal(ctx); err != nil {
		return fmt.Errorf("diffing node: %v", err)
	}

	if err := h.ApplyLocal(ctx); err != nil {
		return fmt.Errorf("applying to local node: %v", err)
	}

	return nil
}

func evalNodes(ctx context.Context, cfg Config, path string, hostnames []string) (*DeployPlan, error) {
	workers := *concurrency
	if len(hostnames) > 0 && len(hostnames) < workers-1 {
		workers = len(hostnames) + 1
	}

	slog.InfoContext(ctx, "evaluating plans", "file", path, "hosts", hostnames, "workers", workers)

	hostnamesBytes, err := json.Marshal(hostnames)
	if err != nil {
		return nil, fmt.Errorf("serializing hostnames to json: %w", err)
	}

	namesToInclude := fmt.Sprintf("builtins.fromJSON %q", string(hostnamesBytes))
	paths, err := cfg.Nix.EvalJobs(ctx, nix.EvalJobsOptions{
		Path: path,
		Args: map[string]string{
			"namesToInclude": namesToInclude,
		},
		Workers: workers,
	})
	if err != nil {
		return nil, fmt.Errorf("running eval: %w", err)
	}

	var configResult nix.EvalJobResult
	var errorAttrs []string
	resultsByAttrs := map[string]nix.EvalJobResult{}
	testsByHost := map[string][]string{}
	for _, r := range paths {
		if r.Error != "" {
			errorAttrs = append(errorAttrs, r.Attr)
		} else if r.Attr == "configJson" {
			configResult = r
		} else if r.AttrPath[0] == "toplevels" {
			resultsByAttrs[r.AttrPath[1]] = r
		} else if r.AttrPath[0] == "tests" {
			testsByHost[r.AttrPath[1]] = append(testsByHost[r.AttrPath[1]], r.DrvPath)
		}
	}
	if len(errorAttrs) > 0 {
		return nil, fmt.Errorf("evaluation failed for one or more attributes (%s)", strings.Join(errorAttrs, ", "))
	}

	if err := cfg.Nix.Realise(ctx, []string{configResult.DrvPath}, false); err != nil {
		return nil, fmt.Errorf("realising config json: %w", err)
	}

	configFile, err := os.Open(configResult.OutPath())
	if err != nil {
		return nil, fmt.Errorf("opening %q: %w", configResult.OutPath(), err)
	}
	defer configFile.Close()

	var plan planConfig
	if err := json.NewDecoder(configFile).Decode(&plan); err != nil {
		return nil, fmt.Errorf("decoding plan json: %w", err)
	}

	dp := &DeployPlan{Phases: plan.Phases, cfg: cfg}
	for name, r := range resultsByAttrs {
		if !dp.ContainsHost(name) {
			continue
		}

		h := NewHost(cfg, name, r.System, r.DrvPath, r.OutPath(), plan.Deployment[name])
		h.Tests = testsByHost[name]
		dp.Hosts = append(dp.Hosts, h)
	}
	return dp, nil
}

func evalLocalNode(ctx context.Context, path string) (*Host, error) {
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

	cfg := NewLocalConfig()

	slog.InfoContext(ctx, "evaluating local host", "name", name)
	if err := cfg.Nix.EvalJSON(ctx, &result, nix.EvalOptions{
		Expr:    evalExpr,
		Include: []string{"plans=" + path},
	}); err != nil {
		return nil, fmt.Errorf("evaluating node: %w", err)
	}
	return NewHost(cfg, name, result.System, result.DrvPath, result.OutPath, DeployConfig{}), nil
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
