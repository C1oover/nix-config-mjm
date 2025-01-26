package nix

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"os"
	"os/exec"
	"strconv"
	"strings"
)

func (_ Real) EvalJobs(ctx context.Context, opts EvalJobsOptions) ([]EvalJobResult, error) {
	args := []string{"--max-memory-size", "2048"}
	if opts.Workers != 0 {
		args = append(args, "--workers", strconv.Itoa(opts.Workers))
	}
	if opts.Expr != "" {
		args = append(args, "--expr", opts.Expr)
	}
	for k, v := range opts.Args {
		args = append(args, "--arg", k, v)
	}
	if opts.Path != "" {
		args = append(args, opts.Path)
	}

	slog.DebugContext(ctx, "running nix-eval-jobs", "args", args)
	cmd := exec.CommandContext(ctx, "nix-eval-jobs", args...)
	cmd.Stderr = os.Stderr
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("running nix-eval-jobs: %w", err)
	}

	lines := strings.Split(string(output), "\n")
	var results []EvalJobResult
	for _, l := range lines {
		if l == "" {
			continue
		}
		var result EvalJobResult
		if err := json.Unmarshal([]byte(l), &result); err != nil {
			return nil, fmt.Errorf("parsing eval result as json: %w", err)
		}
		results = append(results, result)
	}

	slog.DebugContext(ctx, "finished nix-eval-jobs", "result_count", len(results))
	return results, nil
}

func (_ Real) EvalJSON(ctx context.Context, dst interface{}, opts EvalOptions) error {
	args := []string{"eval", "--impure", "--json"}
	if opts.Expr != "" {
		args = append(args, "--expr", opts.Expr)
	}
	if opts.Path != "" {
		args = append(args, "--file", opts.Path)
	}

	slog.DebugContext(ctx, "running nix", "args", args)
	cmd := exec.CommandContext(ctx, "nix", args...)
	cmd.Stderr = os.Stderr
	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("running nix eval: %w", err)
	}

	if err := json.Unmarshal(output, dst); err != nil {
		return fmt.Errorf("unmarshalling json: %v", err)
	}

	slog.DebugContext(ctx, "finished nix")
	return nil
}
