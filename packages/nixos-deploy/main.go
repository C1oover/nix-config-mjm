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

	"git.midna.dev/mjm/nix-config/packages/nixos-deploy/cmd"
	"git.midna.dev/mjm/nix-config/packages/nixos-deploy/nix"
	"github.com/lmittmann/tint"
	"golang.org/x/sync/errgroup"
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

	switch flag.Arg(0) {
	case "deploy":
		if err := handleDeploy(ctx); err != nil {
			slog.ErrorContext(ctx, "deploy failed", "error", err)
			os.Exit(1)
		}
	case "diff":
		if err := handleDiff(ctx); err != nil {
			slog.ErrorContext(ctx, "diff failed", "error", err)
			os.Exit(1)
		}
	case "reboot":
		if err := handleReboot(ctx); err != nil {
			slog.ErrorContext(ctx, "reboot failed", "error", err)
			os.Exit(1)
		}
	case "apply-local":
		if err := handleApplyLocal(ctx); err != nil {
			slog.ErrorContext(ctx, "apply failed", "error", err)
			os.Exit(1)
		}
	default:
		slog.ErrorContext(ctx, "unexpected command", "command", flag.Arg(0))
		os.Exit(1)
	}
}

func newConfig(keyPath string) Config {
	args := []string{
		"-o",
		"BatchMode=yes",
		"-T",
	}

	if keyPath != "" {
		args = append(args, "-o", fmt.Sprintf("IdentityFile=%s", keyPath))
	}

	slog.Debug("ssh options", "opts", args)

	return Config{
		Runner:  cmd.LocalRunner{},
		SSHOpts: args,
	}
}

func handleDeploy(ctx context.Context) error {
	hostnames := flag.Args()
	hostnames = hostnames[1:]

	keyPath, err := generateAndWriteSSHKey(ctx)
	if err != nil {
		return fmt.Errorf("generating ssh key: %w", err)
	}
	defer os.RemoveAll(path.Dir(keyPath))

	plan, err := evalNodes(ctx, newConfig(keyPath), *plansFile, hostnames)
	if err != nil {
		return fmt.Errorf("evaluating nodes: %w", err)
	}

	// remove any local hosts, we don't want to deploy to those
	plan.Hosts = slices.DeleteFunc(plan.Hosts, func(h *Host) bool {
		return h.Kind != HostKindSSH
	})

	if err := plan.EachHost(ctx, func(ctx context.Context, h *Host) error {
		if err := h.Build(ctx, false); err != nil {
			return fmt.Errorf("building node %s: %w", h.Name, err)
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

	if err := plan.deploy(ctx); err != nil {
		return fmt.Errorf("deploying plan: %w", err)
	}

	slog.InfoContext(ctx, "deploy completed")
	return nil
}

func handleDiff(ctx context.Context) error {
	hostnames := flag.Args()
	hostnames = hostnames[1:]

	keyPath, err := generateAndWriteSSHKey(ctx)
	if err != nil {
		return fmt.Errorf("generating ssh key: %w", err)
	}
	defer os.RemoveAll(path.Dir(keyPath))

	plan, err := evalNodes(ctx, newConfig(keyPath), *plansFile, hostnames)
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

	if err := plan.EachHost(ctx, func(ctx context.Context, h *Host) error {
		if err := h.Build(ctx, false); err != nil {
			return fmt.Errorf("building node %s: %w", h.Name, err)
		}
		if err := h.PushToAttic(ctx); err != nil {
			return fmt.Errorf("pushing node %s to attic: %w", h.Name, err)
		}

		if h.Kind == HostKindSSH {
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

	keyPath, err := generateAndWriteSSHKey(ctx)
	if err != nil {
		return fmt.Errorf("generating ssh key: %w", err)
	}
	defer os.RemoveAll(path.Dir(keyPath))

	plan, err := evalNodes(ctx, newConfig(keyPath), *plansFile, hostnames)
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

func evalNodes(ctx context.Context, cfg Config, path string, hostnames []string) (*deployPlan, error) {
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
	paths, err := nix.EvalJobs(ctx, nix.EvalJobsOptions{
		Path: path,
		Args: map[string]string{
			"namesToInclude": namesToInclude,
		},
		Workers: workers,
	})
	if err != nil {
		return nil, fmt.Errorf("running eval: %w", err)
	}

	var configDrv string
	var errorAttrs []string
	pathsByAttrs := map[string]string{}
	for _, p := range paths {
		if p.Error != "" {
			errorAttrs = append(errorAttrs, p.Attr)
		} else if p.Attr == "configJson" {
			configDrv = p.DrvPath
		} else {
			pathsByAttrs[p.Attr] = p.DrvPath
		}
	}
	if len(errorAttrs) > 0 {
		return nil, fmt.Errorf("evaluation failed for one or more nodes (%s): %w", strings.Join(errorAttrs, ", "), err)
	}

	configOut, err := nix.Realise(ctx, configDrv, false)
	if err != nil {
		return nil, fmt.Errorf("realising config json: %w", err)
	}

	configFile, err := os.Open(configOut)
	if err != nil {
		return nil, fmt.Errorf("opening %q: %w", configOut, err)
	}
	defer configFile.Close()

	var plan planConfig
	if err := json.NewDecoder(configFile).Decode(&plan); err != nil {
		return nil, fmt.Errorf("decoding plan json: %w", err)
	}

	var hosts []*Host
	for name, drvPath := range pathsByAttrs {
		if !slices.ContainsFunc(plan.Phases, func(p deployPhase) bool { return slices.Contains(p.Nodes, name) }) {
			continue
		}

		hosts = append(hosts, NewHost(cfg, name, drvPath, plan.Deployment[name]))
	}

	return &deployPlan{
		Phases: plan.Phases,
		Hosts:  hosts,
	}, nil
}

func evalLocalNode(ctx context.Context, path string) (*Host, error) {
	name, err := os.Hostname()
	if err != nil {
		return nil, fmt.Errorf("getting hostname: %w", err)
	}

	evalExpr := fmt.Sprintf("let config = (import ./%s {}).%s; in { drv = config.drvPath; out = config.outPath; }", path, name)

	var result struct {
		DrvPath string `json:"drv"`
		OutPath string `json:"out"`
	}

	slog.InfoContext(ctx, "evaluating local host", "name", name)
	if err := nix.EvalJSON(ctx, &result, nix.EvalOptions{Expr: evalExpr}); err != nil {
		return nil, fmt.Errorf("evaluating node: %w", err)
	}
	return NewLocalHost(newConfig(""), name, result.DrvPath, result.OutPath), nil
}

type deployPlan struct {
	Phases []deployPhase
	Hosts  []*Host
}

type planConfig struct {
	Phases     []deployPhase           `json:"phases"`
	Deployment map[string]DeployConfig `json:"deployment"`
}

type deployPhase struct {
	Name  string   `json:"name"`
	Nodes []string `json:"nodes"`
}

func (p *deployPlan) EachHost(ctx context.Context, f func(context.Context, *Host) error) error {
	g, childCtx := errgroup.WithContext(ctx)
	g.SetLimit(*concurrency)

	for _, h := range p.Hosts {
		g.Go(func() error {
			return f(childCtx, h)
		})
	}
	return g.Wait()
}

func (p *deployPlan) deploy(ctx context.Context) error {
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

		if err := deployPhaseNodes(ctx, phase.Name, phaseNodes); err != nil {
			return fmt.Errorf("deploying phase %s: %w", phase.Name, err)
		}
	}

	return nil
}

func deployPhaseNodes(ctx context.Context, name string, hosts []*Host) error {
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
