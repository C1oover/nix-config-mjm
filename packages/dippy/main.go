package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"os"
	"os/exec"
	"path"
	"runtime"
	"slices"
	"strconv"
	"strings"
	"time"

	"git.midna.dev/mjm/nix-config/packages/dippy/infra"
	"git.midna.dev/mjm/nix-config/packages/dippy/nix"
	"github.com/lmittmann/tint"
)

var (
	plansFile   = flag.String("plans", "plans.nix", "File to evaluate for deploy plans")
	concurrency = flag.Int("concurrency", runtime.NumCPU(), "Number of nodes to evaluate/build concurrently")
	nom         = flag.Bool("nom", os.Getenv("CI") == "", "Whether to run builds through nix-output-monitor")
	forceGoal   = flag.String("goal", "", "Force use of a specific goal regardless of reboot check")
	pushToAttic = flag.Bool("attic", true, "Whether to push the built system to the attic cache")
	runTests    = flag.Bool("tests", true, "Whether to run NixOS VM tests")

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
	case "apply-infra":
		err = handleApplyInfra(ctx)
	case "diff-infra":
		err = handleDiffInfra(ctx)
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

	s := sectionStart("Evaluating hosts and tests", true)
	plan, err := evalNodes(ctx, &cfg, *plansFile, hostnames)
	if err != nil {
		return fmt.Errorf("evaluating nodes: %w", err)
	}
	sectionEnd(s)

	// remove any local hosts, we don't want to deploy to those
	plan.Hosts = slices.DeleteFunc(plan.Hosts, func(h *Host) bool {
		return h.IsLocal()
	})

	s = sectionStart("Building hosts", false)
	if err := plan.Build(ctx, *nom); err != nil {
		return fmt.Errorf("building all hosts: %w", err)
	}
	sectionEnd(s)

	if *runTests {
		s = sectionStart("Running NixOS VM tests", false)
		if err := plan.Test(ctx, *nom); err != nil {
			return fmt.Errorf("running all tests: %w", err)
		}
		sectionEnd(s)
	}

	if err := atticLogin(ctx, &cfg); err != nil {
		return fmt.Errorf("logging in to attic: %w", err)
	}

	s = sectionStart("Pushing systems to hosts and attic", true)
	if err := plan.EachHost(ctx, func(ctx context.Context, h *Host) error {
		if err := h.Push(ctx); err != nil {
			return fmt.Errorf("pushing node %s: %w", h.Name, err)
		}
		if *pushToAttic {
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

	if len(hostnames) == 0 {
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

func handleDiff(ctx context.Context) error {
	hostnames := flag.Args()
	hostnames = hostnames[1:]

	cfg, err := GenerateConfig(ctx)
	if err != nil {
		return fmt.Errorf("generating config: %w", err)
	}
	defer cfg.Cleanup()

	s := sectionStart("Evaluating hosts and tests", true)
	plan, err := evalNodes(ctx, &cfg, *plansFile, hostnames)
	if err != nil {
		return fmt.Errorf("evaluating nodes: %w", err)
	}
	sectionEnd(s)

	slog.DebugContext(ctx, "creating temp dir for diffs")
	diffsDir, err := os.MkdirTemp("", "dippy-diffs")
	if err != nil {
		return fmt.Errorf("creating temp dir: %w", err)
	}
	defer os.RemoveAll(diffsDir)
	slog.DebugContext(ctx, "created temp dir for diffs", "path", diffsDir)

	s = sectionStart("Building hosts", false)
	if err := plan.Build(ctx, *nom); err != nil {
		return fmt.Errorf("building all hosts: %w", err)
	}
	sectionEnd(s)

	if *runTests {
		s = sectionStart("Running NixOS VM tests", false)
		if err := plan.Test(ctx, *nom); err != nil {
			return fmt.Errorf("running all tests: %w", err)
		}
		sectionEnd(s)
	}

	if err := atticLogin(ctx, &cfg); err != nil {
		return fmt.Errorf("logging in to attic: %w", err)
	}

	s = sectionStart("Pushing and diffing hosts", true)
	if err := plan.EachHost(ctx, func(ctx context.Context, h *Host) error {
		if *pushToAttic {
			if err := h.PushToAttic(ctx); err != nil {
				return fmt.Errorf("pushing node %s to attic: %w", h.Name, err)
			}
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
	sectionEnd(s)

	if len(hostnames) == 0 {
		vault, err := cfg.Vault(ctx)
		if err != nil {
			return fmt.Errorf("getting vault client: %w", err)
		}
		s = sectionStart("Previewing infra changes", false)
		if err := infra.Preview(ctx, vault, plan.Infra); err != nil {
			return fmt.Errorf("previewing infra changes: %w", err)
		}
		sectionEnd(s)
	}

	slog.DebugContext(ctx, "aggregating diffs", "path", diffsDir)
	aggregated, err := aggregateDiffs(ctx, diffsDir)
	if err != nil {
		return fmt.Errorf("aggregating diffs: %w", err)
	}

	var body strings.Builder
	if err := aggregated.Write(&body); err != nil {
		return fmt.Errorf("writing formatted summary: %w", err)
	}

	if body.Len() == 0 {
		body.WriteString("No package changes for server hosts.\n")
	}

	gitlabBaseURL := os.Getenv("CI_API_V4_URL")
	if gitlabBaseURL == "" {
		io.WriteString(os.Stdout, body.String())
	} else {
		gitlabToken, err := cfg.GetSecret(ctx, "gitlab_token")

		projectID, err := strconv.Atoi(os.Getenv("CI_PROJECT_ID"))
		if err != nil {
			return fmt.Errorf("converting project ID %q to int: %w", os.Getenv("CI_PROJECT_ID"), err)
		}

		mergeRequestID, err := strconv.Atoi(os.Getenv("CI_MERGE_REQUEST_IID"))
		if err != nil {
			return fmt.Errorf("converting merge request ID %q to int: %w", os.Getenv("CI_MERGE_REQUEST_IID"), err)
		}

		slog.DebugContext(ctx, "creating merge request note", "base_url", gitlabBaseURL, "project", projectID, "merge_request", mergeRequestID)

		if err := createMergeRequestNote(ctx, &createMergeRequestNoteArgs{
			BaseURL:        gitlabBaseURL,
			Token:          gitlabToken,
			Project:        projectID,
			MergeRequestID: mergeRequestID,
			Body:           body.String(),
		}); err != nil {
			return fmt.Errorf("creating merge request note: %w", err)
		}

		slog.InfoContext(ctx, "created merge request note")
	}

	return nil
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

	plan, err := evalNodes(ctx, &cfg, *plansFile, hostnames)
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
	cfg, err := NewLocalConfig()
	if err != nil {
		return fmt.Errorf("generating config: %w", err)
	}

	h, err := evalLocalNode(ctx, &cfg, *plansFile)
	if err != nil {
		return fmt.Errorf("evaluating node: %w", err)
	}

	if err := h.Build(ctx, true); err != nil {
		return fmt.Errorf("building node: %w", err)
	}

	if *pushToAttic {
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

func handleApplyInfra(ctx context.Context) error {
	cfg, err := NewLocalConfig()
	if err != nil {
		return fmt.Errorf("generating config: %w", err)
	}

	slog.InfoContext(ctx, "evaluating infra config", "file", *plansFile)

	result := new(infra.Input)
	if err := cfg.Nix.EvalJSON(ctx, result, nix.EvalOptions{
		Expr:    "(import <plans> {}).infra",
		Include: []string{"plans=" + *plansFile},
	}); err != nil {
		return fmt.Errorf("evaluating infra data from nix: %w", err)
	}

	vault, err := cfg.Vault(ctx)
	if err != nil {
		return fmt.Errorf("getting vault client: %w", err)
	}
	if err := infra.Apply(ctx, vault, result); err != nil {
		return fmt.Errorf("applying infra: %w", err)
	}

	return nil
}

func handleDiffInfra(ctx context.Context) error {
	cfg, err := NewLocalConfig()
	if err != nil {
		return fmt.Errorf("generating config: %w", err)
	}

	slog.InfoContext(ctx, "evaluating infra config", "file", *plansFile)

	result := new(infra.Input)
	if err := cfg.Nix.EvalJSON(ctx, result, nix.EvalOptions{
		Expr:    "(import <plans> {}).infra",
		Include: []string{"plans=" + *plansFile},
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

func evalNodes(ctx context.Context, cfg *Config, path string, hostnames []string) (*DeployPlan, error) {
	workers := *concurrency
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
