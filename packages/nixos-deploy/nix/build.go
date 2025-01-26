package nix

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"os/exec"
)

// Realise builds a derivation from an evaluated .drv file and returns the path to the output.
func (_ Real) Realise(ctx context.Context, drvPath string, useNom bool) error {
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
			return fmt.Errorf("creating nom in pipe: %w", err)
		}

		cmd.Stdout = nomIn
		cmd.Stderr = nomIn

		slog.DebugContext(ctx, "running nom")
		if err := nomCmd.Start(); err != nil {
			return fmt.Errorf("starting nom: %w", err)
		}
		slog.DebugContext(ctx, "running nix-store", "args", args)
		if err := cmd.Start(); err != nil {
			return fmt.Errorf("starting nix-store: %w", err)
		}
		if err := cmd.Wait(); err != nil {
			return fmt.Errorf("running nix-store: %w", err)
		}

		slog.DebugContext(ctx, "finished nix-store")
		nomIn.Close()
		if err := nomCmd.Wait(); err != nil {
			return fmt.Errorf("running nom: %w", err)
		}

		slog.DebugContext(ctx, "finished nom")
		return nil
	} else {
		cmd.Stderr = os.Stderr
		slog.DebugContext(ctx, "running nix-store", "args", args)
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("running nix-store: %w", err)
		}

		slog.DebugContext(ctx, "finished nix-store")
		return nil
	}
}
