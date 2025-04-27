package main

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"path"
	"strings"
	"time"

	"git.midna.dev/mjm/nix-config/packages/dippy/cmd"
	"git.midna.dev/mjm/nix-config/packages/dippy/nix"
	consulapi "github.com/hashicorp/consul/api"
	"golang.org/x/crypto/ssh"
)

type Host struct {
	Name         string
	System       string
	DrvPath      string
	OutPath      string
	DeployConfig DeployConfig
	RebootNeeded bool
	cfg          *Config
	log          *slog.Logger
	remoteRunner cmd.Runner
}

type DeployConfig struct {
	TargetHost   *string  `json:"targetHost"`
	TargetUser   *string  `json:"targetUser"`
	Tags         []string `json:"tags"`
	AutoReboot   bool     `json:"rebootAutomatically"`
	ConsulChecks []string `json:"consulChecks"`
}

func NewHost(cfg *Config, name string, system string, drvPath string, outPath string, deployConfig DeployConfig) *Host {
	logger := slog.Default().WithGroup("host").With("name", name)
	return &Host{
		Name:         name,
		System:       system,
		DrvPath:      drvPath,
		OutPath:      outPath,
		DeployConfig: deployConfig,
		cfg:          cfg,
		log:          logger,
	}
}

func (h *Host) IsLocal() bool {
	return h.DeployConfig.TargetHost == nil
}

func (h *Host) IsRemote() bool {
	return !h.IsLocal()
}

func (h *Host) IsDarwin() bool {
	return strings.HasSuffix(h.System, "-darwin")
}

func (h *Host) Build(ctx context.Context, useNom bool) error {
	l := h.log.With("drv_path", h.DrvPath)
	l.InfoContext(ctx, "building host")

	if err := h.cfg.Nix.Realise(ctx, []string{h.DrvPath}, useNom); err != nil {
		return fmt.Errorf("realising node %s: %w", h.Name, err)
	}

	l.InfoContext(ctx, "finished building host", "out_path", h.OutPath)
	return nil
}

func (h *Host) Push(ctx context.Context) error {
	if h.IsLocal() {
		return nil
	}

	toUrl := fmt.Sprintf("ssh-ng://%s@%s", *h.DeployConfig.TargetUser, *h.DeployConfig.TargetHost)
	l := h.log.With("out_path", h.OutPath, "target", toUrl)
	l.InfoContext(ctx, "pushing system")

	if err := h.cfg.Nix.Copy(ctx, nix.CopyOptions{
		Installables: []string{h.OutPath},
		To:           toUrl,
	}); err != nil {
		return fmt.Errorf("copying closure for %s: %w", h.Name, err)
	}

	l.InfoContext(ctx, "pushed system")
	return nil
}

func (h *Host) PushToAttic(ctx context.Context) error {
	l := h.log.With("out_path", h.OutPath)
	l.InfoContext(ctx, "pushing to attic cache")

	if err := h.cfg.Runner.Execute(ctx, "attic", "push", "homelab-dippy:homelab", h.OutPath); err != nil {
		return fmt.Errorf("running attic push: %w", err)
	}

	l.InfoContext(ctx, "pushed to attic cache")
	return nil
}

func (h *Host) CheckRebootNeeded(ctx context.Context) error {
	if h.IsDarwin() {
		return nil
	}

	h.log.InfoContext(ctx, "checking if reboot is needed")

	output, err := h.ExecuteOutput(ctx, path.Join(h.OutPath, "bin/nvd-json"), "reboot-check", h.OutPath)
	if err != nil {
		return fmt.Errorf("running nvd-json: %w", err)
	}

	var result struct {
		RebootNeeded bool `json:"reboot_needed"`
	}
	if err := json.Unmarshal(output, &result); err != nil {
		return fmt.Errorf("decoding nvd-json output: %w", err)
	}

	h.RebootNeeded = result.RebootNeeded
	return nil
}

func (h *Host) Diff(ctx context.Context) ([]byte, error) {
	h.log.InfoContext(ctx, "diffing against current system", "out_path", h.OutPath)

	output, err := h.ExecuteOutput(ctx, path.Join(h.OutPath, "bin/nvd-json"), "diff", "/run/current-system", h.OutPath)
	if err != nil {
		return nil, fmt.Errorf("running nvd-json: %w", err)
	}

	return output, nil
}

func (h *Host) DiffLocal(ctx context.Context) error {
	if err := h.cfg.Runner.Execute(ctx, "nvd", "diff", "/run/current-system", h.OutPath); err != nil {
		return fmt.Errorf("running nvd: %w", err)
	}

	if err := h.CheckRebootNeeded(ctx); err != nil {
		return fmt.Errorf("checking if reboot is needed: %w", err)
	}

	return nil
}

const systemProfile = "/nix/var/nix/profiles/system"

func (h *Host) Deploy(ctx context.Context, goal string) error {
	h.log.InfoContext(ctx, "deploying")

	if goal == "" {
		goal = "switch"
		if h.RebootNeeded {
			goal = "boot"
		}
	}

	if err := h.apply(ctx, goal); err != nil {
		return fmt.Errorf("applying: %w", err)
	}

	if goal == "boot" && h.DeployConfig.AutoReboot {
		if err := h.Reboot(ctx); err != nil {
			return fmt.Errorf("rebooting: %w", err)
		}
	}

	// skip consul checks if the boot goal was used but the node wasn't rebooted yet
	if goal != "boot" || h.DeployConfig.AutoReboot {
		if err := h.WaitUntilHealthy(ctx); err != nil {
			return fmt.Errorf("waiting for %s to be healthy: %w", h.Name, err)
		}
	}

	h.log.InfoContext(ctx, "deployed")
	return nil
}

func (h *Host) ApplyLocal(ctx context.Context) error {
	goal := "switch"
	if h.RebootNeeded {
		goal = "boot"
	}

	reader := bufio.NewReader(os.Stdin)
	for {
		fmt.Fprintf(os.Stderr, "Apply these changes with %s goal? ", goal)
		input, err := reader.ReadString('\n')
		if err != nil {
			return fmt.Errorf("confirming apply: %v", err)
		}
		input = strings.ToLower(strings.TrimSpace(input))

		if input == "y" || input == "yes" {
			break
		}
		if input == "n" || input == "no" {
			return nil
		}
		if input == "switch" || input == "boot" {
			goal = input
			h.log.InfoContext(ctx, "overriding goal", "goal", goal)
			break
		}
	}

	if err := h.apply(ctx, goal); err != nil {
		return fmt.Errorf("applying: %w", err)
	}

	if goal == "boot" {
		fmt.Fprintln(os.Stderr, "Reboot to apply changes.")
	}
	return nil
}

func (h *Host) apply(ctx context.Context, goal string) error {
	h.log.InfoContext(ctx, "setting system profile", "out_path", h.OutPath)
	if err := h.Execute(ctx, "sudo", "nix-env", "--profile", systemProfile, "--set", h.OutPath); err != nil {
		return fmt.Errorf("setting system profile: %w", err)
	}

	if err := h.activate(ctx, goal); err != nil {
		return fmt.Errorf("activating system: %w", err)
	}

	return nil
}

func (h *Host) activate(ctx context.Context, goal string) error {
	h.log.InfoContext(ctx, "activating system", "goal", goal)

	if h.IsDarwin() {
		if err := h.Execute(ctx, "sudo", path.Join(systemProfile, "sw/bin/darwin-rebuild"), "activate"); err != nil {
			return fmt.Errorf("running darwin-rebuild activate: %w", err)
		}
	} else {
		if err := h.Execute(ctx, "sudo", path.Join(systemProfile, "bin/switch-to-configuration"), goal); err != nil {
			return fmt.Errorf("running switch-to-configuration: %w", err)
		}
	}

	return nil
}

func (h *Host) WaitUntilHealthy(ctx context.Context) error {
	if len(h.DeployConfig.ConsulChecks) == 0 {
		return nil
	}

	h.log.InfoContext(ctx, "waiting for healthy host", "checks", h.DeployConfig.ConsulChecks)
	// delay a bit at the start to be sure the state in Consul reflects the deploy
	time.Sleep(20 * time.Second)

	cfg := consulapi.DefaultNonPooledConfig()
	cfg.Address = "https://consul.midna.dev"

	client, err := consulapi.NewClient(cfg)
	if err != nil {
		return fmt.Errorf("creating consul client: %w", err)
	}

	var waitIndex uint64
	for {
		checks, meta, err := client.Health().Node(h.Name, &consulapi.QueryOptions{
			WaitIndex: waitIndex,
		})
		if err != nil {
			return fmt.Errorf("checking node health in consul: %w", err)
		}

		var anyFailing bool
		for _, svcName := range h.DeployConfig.ConsulChecks {
			var anyFound bool
			for _, check := range checks {
				if check.ServiceName != svcName {
					continue
				}

				anyFound = true
				h.log.InfoContext(ctx, "health check result", slog.Group("check", "name", check.Name, "status", check.Status))
				if check.Status != consulapi.HealthPassing {
					anyFailing = true
				}
			}

			if !anyFound {
				h.log.InfoContext(ctx, "no checks found", "service", svcName)
				anyFailing = true
			}
		}

		if anyFailing {
			h.log.InfoContext(ctx, "host is unhealthy")
		} else {
			break
		}

		waitIndex = meta.LastIndex
	}

	h.log.InfoContext(ctx, "host is healthy")
	return nil
}

func (h *Host) Reboot(ctx context.Context) error {
	h.log.InfoContext(ctx, "rebooting")

	oldID, err := h.getBootID(ctx)
	if err != nil {
		return fmt.Errorf("getting original boot id: %w", err)
	}
	h.log.DebugContext(ctx, "got original boot id", "boot_id", oldID)

	if err := h.Execute(ctx, "sudo", "reboot"); err != nil && !errors.Is(err, &ssh.ExitMissingError{}) {
		return fmt.Errorf("initiating reboot: %w", err)
	}

	h.log.InfoContext(ctx, "waiting for reboot")

	for {
		newID, err := h.getBootID(ctx)
		h.log.DebugContext(ctx, "check for new boot id", slog.Group("boot_id", "old", oldID, "new", newID), "err", err)
		if err == nil && newID != oldID {
			break
		}

		// the existing connection to the host may not be good or valid anymore
		if err != nil {
			h.remoteRunner = nil
		}
		time.Sleep(2 * time.Second)
	}

	h.log.InfoContext(ctx, "rebooted")
	return nil
}

func (h *Host) getBootID(ctx context.Context) (string, error) {
	ctx, cancel := context.WithTimeoutCause(ctx, 10*time.Second, fmt.Errorf("timeout checking boot ID"))
	defer cancel()

	output, err := h.ExecuteOutput(ctx, "cat", "/proc/sys/kernel/random/boot_id")
	if err != nil {
		return "", fmt.Errorf("getting boot id: %w", err)
	}

	return strings.TrimSpace(string(output)), nil
}

func (h *Host) Execute(ctx context.Context, name string, args ...string) error {
	runner, err := h.getRunner(ctx)
	if err != nil {
		return err
	}

	return runner.Execute(ctx, name, args...)
}

func (h *Host) ExecuteOutput(ctx context.Context, name string, args ...string) ([]byte, error) {
	runner, err := h.getRunner(ctx)
	if err != nil {
		return nil, err
	}

	return runner.ExecuteOutput(ctx, name, args...)
}

var _ cmd.Runner = (*Host)(nil)

func (h *Host) getRunner(ctx context.Context) (cmd.Runner, error) {
	if h.IsLocal() {
		return h.cfg.Runner, nil
	}

	if h.remoteRunner != nil {
		h.log.DebugContext(ctx, "reusing existing remote runner")
		return h.remoteRunner, nil
	}

	h.log.DebugContext(ctx, "creating new remote runner")

	runner, err := h.cfg.RemoteRunner(*h.DeployConfig.TargetHost, *h.DeployConfig.TargetUser)
	if err != nil {
		return nil, fmt.Errorf("creating remote runner for %s: %w", h.Name, err)
	}
	h.remoteRunner = runner
	return runner, nil
}
