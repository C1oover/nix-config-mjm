package main

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path"
	"strings"
	"time"

	"git.midna.dev/mjm/nix-config/packages/nixos-deploy/nix"
	consulapi "github.com/hashicorp/consul/api"
)

type HostKind int

const (
	HostKindLocal HostKind = iota
	HostKindSSH
)

type Host struct {
	Name         string
	Kind         HostKind
	DrvPath      string
	OutPath      string
	DeployConfig DeployConfig
	RebootNeeded bool
}

type DeployConfig struct {
	TargetHost   *string  `json:"targetHost"`
	TargetUser   *string  `json:"targetUser"`
	Tags         []string `json:"tags"`
	AutoReboot   bool     `json:"rebootAutomatically"`
	ConsulChecks []string `json:"consulChecks"`
}

func (h *Host) sshTarget() string {
	return fmt.Sprintf("%s@%s", *h.DeployConfig.TargetUser, *h.DeployConfig.TargetHost)
}

func (h *Host) CopyClosure(ctx context.Context, p string, sshOpts []string) error {
	if h.Kind == HostKindLocal {
		return nil
	}

	toUrl := fmt.Sprintf("ssh-ng://%s", h.sshTarget())
	cmd := exec.CommandContext(ctx, "nix", "copy", "--no-check-sigs", "--to", toUrl, p)
	cmd.Stderr = os.Stderr
	cmd.Stdout = os.Stdout

	sshOptsStr := strings.Join(sshOpts, " ")
	cmd.Env = append(os.Environ(), fmt.Sprintf("NIX_SSHOPTS=%s", sshOptsStr))

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("running nix copy: %w", err)
	}
	return nil
}

func (h *Host) Build(ctx context.Context, useNom bool) error {
	if useNom && h.OutPath == "" {
		return fmt.Errorf("building with nom requires the out path to already be set, but it is empty")
	}

	log.Printf("building %s from %s", h.Name, h.DrvPath)

	outPath, err := nix.Realise(ctx, h.DrvPath, useNom)
	if err != nil {
		return fmt.Errorf("realising node %s: %w", h.Name, err)
	}

	if !useNom {
		h.OutPath = outPath
	}
	log.Printf("built %s to %s", h.Name, h.OutPath)
	return nil
}

func (h *Host) Push(ctx context.Context, sshOpts []string) error {
	log.Printf("pushing %s to %s", h.Name, *h.DeployConfig.TargetHost)

	if err := h.CopyClosure(ctx, h.OutPath, sshOpts); err != nil {
		return fmt.Errorf("copying closure for %s: %w", h.Name, err)
	}

	log.Printf("pushed %s", h.Name)
	return nil
}

func (h *Host) PushToAttic(ctx context.Context) error {
	log.Printf("pushing %s to attic cache", h.Name)

	cmd := exec.CommandContext(ctx, "attic", "push", "homelab", h.OutPath)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("running attic push: %w", err)
	}

	return nil
}

func (h *Host) CheckRebootNeeded(ctx context.Context, sshOpts []string) error {
	log.Printf("checking if %s requires a reboot", h.Name)

	output, err := h.runCommand(ctx, sshOpts, path.Join(h.OutPath, "bin/nvd-json"), "reboot-check", h.OutPath)
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

func (h *Host) Diff(ctx context.Context, sshOpts []string) ([]byte, error) {
	log.Printf("diffing %s against current system", h.Name)

	output, err := h.runCommand(ctx, sshOpts, path.Join(h.OutPath, "bin/nvd-json"), "diff", "/run/current-system", h.OutPath)
	if err != nil {
		return nil, fmt.Errorf("running nvd-json: %w", err)
	}

	return output, nil
}

func (h *Host) DiffLocal(ctx context.Context) error {
	cmd := exec.CommandContext(ctx, "nvd", "diff", "/run/current-system", h.OutPath)
	cmd.Stderr = os.Stderr
	cmd.Stdout = os.Stdout
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("running nvd: %w", err)
	}

	if err := h.CheckRebootNeeded(ctx, nil); err != nil {
		return fmt.Errorf("checking if reboot is needed: %w", err)
	}

	return nil
}

const systemProfile = "/nix/var/nix/profiles/system"

func (h *Host) Deploy(ctx context.Context, sshOpts []string) error {
	log.Printf("deploying %s", h.Name)

	goal := "switch"
	if h.RebootNeeded {
		goal = "boot"
	}

	if err := h.apply(ctx, sshOpts, goal); err != nil {
		return fmt.Errorf("applying: %w", err)
	}

	if h.RebootNeeded && h.DeployConfig.AutoReboot {
		if err := h.Reboot(ctx, sshOpts); err != nil {
			return fmt.Errorf("rebooting: %w", err)
		}
	}

	// skip consul checks if the boot goal was used but the node wasn't rebooted yet
	if !h.RebootNeeded || h.DeployConfig.AutoReboot {
		if err := h.WaitUntilHealthy(ctx); err != nil {
			return fmt.Errorf("waiting for %s to be healthy: %w", h.Name, err)
		}
	}

	log.Printf("deployed %s successfully", h.Name)
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
	}

	if err := h.apply(ctx, nil, goal); err != nil {
		return fmt.Errorf("applying: %w", err)
	}

	if h.RebootNeeded {
		log.Print("reboot to apply changes")
	}
	return nil
}

func (h *Host) apply(ctx context.Context, sshOpts []string, goal string) error {
	log.Printf("setting new system profile for %s", h.Name)
	if _, err := h.runCommand(ctx, sshOpts, "nix-env", "--profile", systemProfile, "--set", h.OutPath); err != nil {
		return fmt.Errorf("setting system profile: %w", err)
	}

	log.Printf("activating new system for %s via %s", h.Name, goal)
	if _, err := h.runCommand(ctx, sshOpts, path.Join(systemProfile, "bin/switch-to-configuration"), goal); err != nil {
		return fmt.Errorf("activating system: %w", err)
	}

	return nil
}

func (h *Host) WaitUntilHealthy(ctx context.Context) error {
	if len(h.DeployConfig.ConsulChecks) == 0 {
		return nil
	}

	log.Printf("waiting for %s to be healthy", h.Name)
	// delay a bit at the start to be sure the state in Consul reflects the deploy
	time.Sleep(20 * time.Second)

	cfg := consulapi.DefaultNonPooledConfig()
	cfg.Address = "consul.service.consul:8500"

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
				log.Printf("%s: %s", check.Name, check.Status)
				if check.Status != consulapi.HealthPassing {
					anyFailing = true
				}
			}

			if !anyFound {
				log.Printf("no checks found for service %s", svcName)
				anyFailing = true
			}
		}

		if anyFailing {
			log.Printf("at least one required service is unhealthy, continuing to wait")
		} else {
			break
		}

		waitIndex = meta.LastIndex
	}

	log.Printf("%s is healthy", h.Name)
	return nil
}

func (h *Host) Reboot(ctx context.Context, sshOpts []string) error {
	log.Printf("rebooting %s", h.Name)

	oldID, err := h.getBootID(ctx, sshOpts)
	if err != nil {
		return fmt.Errorf("getting original boot id: %w", err)
	}

	if _, err := h.runCommand(ctx, sshOpts, "reboot"); err != nil && err.(*exec.ExitError).ExitCode() != 255 {
		return fmt.Errorf("initiating reboot: %w", err)
	}

	log.Printf("waiting for %s to reboot", h.Name)

	for {
		newID, err := h.getBootID(ctx, sshOpts)
		if err == nil && newID != oldID {
			break
		}

		time.Sleep(2 * time.Second)
	}

	log.Printf("rebooted %s", h.Name)
	return nil
}

func (h *Host) getBootID(ctx context.Context, sshOpts []string) (string, error) {
	ctx, cancel := context.WithTimeoutCause(ctx, 10*time.Second, fmt.Errorf("timeout checking boot ID"))
	defer cancel()

	output, err := h.runCommand(ctx, sshOpts, "cat", "/proc/sys/kernel/random/boot_id")
	if err != nil {
		return "", fmt.Errorf("getting boot id: %w", err)
	}

	return strings.TrimSpace(string(output)), nil
}

// TODO consider doing SSH from Go
// would require reimplementing some things to get it to read keys like ssh does
func (h *Host) runCommand(ctx context.Context, sshOpts []string, name string, args ...string) ([]byte, error) {
	var cmd *exec.Cmd

	switch h.Kind {
	case HostKindSSH:
		sshArgs := []string{h.sshTarget()}
		sshArgs = append(sshArgs, sshOpts...)
		sshArgs = append(sshArgs, "--", "sudo", name)
		sshArgs = append(sshArgs, args...)

		cmd = exec.CommandContext(ctx, "ssh", sshArgs...)
	case HostKindLocal:
		cmdArgs := []string{name}
		cmdArgs = append(cmdArgs, args...)

		cmd = exec.CommandContext(ctx, "sudo", cmdArgs...)
	}

	cmd.Stderr = os.Stderr
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("running command on %s: %w", h.Name, err)
	}

	return output, nil
}
