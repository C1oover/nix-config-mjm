package nix

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"os"
	"os/exec"
	"strconv"
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

	output, err := cmd.StdoutPipe()
	if err != nil {
		return nil, fmt.Errorf("creating stdout pipe: %w", err)
	}

	if err := cmd.Start(); err != nil {
		return nil, fmt.Errorf("starting nix-eval-jobs: %w", err)
	}

	s := bufio.NewScanner(output)
	var results []EvalJobResult
	for s.Scan() {
		if len(s.Bytes()) == 0 {
			continue
		}
		var result EvalJobResult
		if err := json.Unmarshal(s.Bytes(), &result); err != nil {
			return nil, fmt.Errorf("parsing eval result as json: %w", err)
		}

		slog.DebugContext(ctx, "eval result", "attr", result.Attr, "error", result.Error, "drv_path", result.DrvPath, "out_path", result.OutPath())
		results = append(results, result)
	}

	if s.Err() != nil {
		return nil, fmt.Errorf("scanning nix-eval-jobs output: %w", s.Err())
	}

	if err := cmd.Wait(); err != nil {
		return nil, fmt.Errorf("running nix-eval-jobs: %w", err)
	}

	slog.DebugContext(ctx, "finished nix-eval-jobs", "result_count", len(results))
	return results, nil
}

func (_ Real) EvalJSON(ctx context.Context, dst any, opts EvalOptions) error {
	args := []string{"eval", "--impure", "--json"}
	if opts.Expr != "" {
		args = append(args, "--expr", opts.Expr)
	}
	for _, s := range opts.Include {
		args = append(args, "--include", s)
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
