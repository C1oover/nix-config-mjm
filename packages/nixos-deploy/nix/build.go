package nix

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// Realise builds a derivation from an evaluated .drv file and returns the path to the output.
func Realise(ctx context.Context, drvPath string, useNom bool) (string, error) {
	args := []string{"--no-gc-warning", "--realise", drvPath}
	if useNom {
		args = append(args, "--log-format", "internal-json", "-v")
	}

	cmd := exec.CommandContext(ctx, "nix-store", args...)
	if useNom {
		nomCmd := exec.CommandContext(ctx, "nom", "--json")
		nomCmd.Stdout = os.Stdout
		nomCmd.Stderr = os.Stderr
		nomIn, err := nomCmd.StdinPipe()
		if err != nil {
			return "", fmt.Errorf("creating nom in pipe: %w", err)
		}

		cmd.Stdout = nomIn
		cmd.Stderr = nomIn

		if err := nomCmd.Start(); err != nil {
			return "", fmt.Errorf("starting nom: %w", err)
		}
		if err := cmd.Start(); err != nil {
			return "", fmt.Errorf("starting nix-store: %w", err)
		}
		if err := cmd.Wait(); err != nil {
			return "", fmt.Errorf("running nix-store: %w", err)
		}

		nomIn.Close()
		if err := nomCmd.Wait(); err != nil {
			return "", fmt.Errorf("running nom: %w", err)
		}

		return "", nil
	} else {
		cmd.Stderr = os.Stderr
		output, err := cmd.Output()
		if err != nil {
			return "", fmt.Errorf("running nix-store: %w", err)
		}

		return strings.TrimSpace(string(output)), nil
	}
}
